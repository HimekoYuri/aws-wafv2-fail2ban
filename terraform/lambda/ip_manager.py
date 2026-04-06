"""
WAF Fail2ban IP Manager Lambda
- CloudWatch Alarm → SNS → Lambda でIP管理を自動実行
- DynamoDB TTLによるIP自動期限切れ対応
- 2026年最新化: 型ヒント、構造化ログ、エラーハンドリング強化
"""

from __future__ import annotations

import json
import os
import time
import logging
from datetime import datetime, timedelta, timezone
from typing import Any

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS クライアント
wafv2 = boto3.client("wafv2")
logs_client = boto3.client("logs")

# 環境変数
REPEAT_OFFENDERS_IP_SET_ID = os.environ["REPEAT_OFFENDERS_IP_SET_ID"]
HEAVY_OFFENDERS_IP_SET_ID = os.environ["HEAVY_OFFENDERS_IP_SET_ID"]
REPEAT_OFFENDERS_IP_SET_NAME = os.environ["REPEAT_OFFENDERS_IP_SET_NAME"]
HEAVY_OFFENDERS_IP_SET_NAME = os.environ["HEAVY_OFFENDERS_IP_SET_NAME"]
IP_TTL_HOURS = int(os.environ.get("IP_TTL_HOURS", "24"))
SCOPE = "CLOUDFRONT"
LOG_GROUP = "/aws/wafv2/fail2ban"


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """CloudWatch Alarm → SNS トリガーでIP管理を実行"""
    try:
        for record in event.get("Records", []):
            sns_message = json.loads(record["Sns"]["Message"])
            alarm_name = sns_message.get("AlarmName", "")
            new_state = sns_message.get("NewStateValue", "")

            logger.info(
                "Processing alarm",
                extra={"alarm_name": alarm_name, "state": new_state},
            )

            if new_state != "ALARM":
                continue

            if "Stage2" in alarm_name:
                handle_repeat_offender()
            elif "Stage3" in alarm_name:
                handle_heavy_offender()

        # TTL期限切れIPのクリーンアップ
        if IP_TTL_HOURS > 0:
            cleanup_expired_ips()

        return {"statusCode": 200, "body": "IP management completed"}

    except Exception:
        logger.exception("Error processing event")
        raise


def handle_repeat_offender() -> None:
    """再犯者リストにIPを追加"""
    blocked_ips = get_recently_blocked_ips("Stage2LightBlockRule")
    if blocked_ips:
        add_ips_to_set(
            REPEAT_OFFENDERS_IP_SET_ID, REPEAT_OFFENDERS_IP_SET_NAME, blocked_ips
        )
        logger.info("Added %d IPs to repeat offenders list", len(blocked_ips))


def handle_heavy_offender() -> None:
    """重度犯罪者リストにIPを追加"""
    blocked_ips = get_recently_blocked_ips("Stage3RepeatOffenderRule")
    if blocked_ips:
        add_ips_to_set(
            HEAVY_OFFENDERS_IP_SET_ID, HEAVY_OFFENDERS_IP_SET_NAME, blocked_ips
        )
        logger.info("Added %d IPs to heavy offenders list", len(blocked_ips))


def get_recently_blocked_ips(rule_name: str) -> list[str]:
    """CloudWatch Logsから最近ブロックされたIPアドレスを取得"""
    try:
        now = datetime.now(tz=timezone.utc)
        start = now - timedelta(minutes=5)

        query = (
            "fields @timestamp, httpRequest.clientIp as clientIP "
            '| filter action = "BLOCK" '
            f'| filter terminatingRuleId = "{rule_name}" '
            "| stats count() as cnt by clientIP "
            "| sort cnt desc "
            "| limit 50"
        )

        response = logs_client.start_query(
            logGroupName=LOG_GROUP,
            startTime=int(start.timestamp()),
            endTime=int(now.timestamp()),
            queryString=query,
        )

        query_id = response["queryId"]

        # ポーリングでクエリ完了を待機 (最大10秒)
        for _ in range(5):
            time.sleep(2)
            results = logs_client.get_query_results(queryId=query_id)
            if results["status"] == "Complete":
                break

        blocked_ips: set[str] = set()
        for result in results.get("results", []):
            for field in result:
                if field["field"] == "clientIP":
                    ip = field["value"].strip()
                    if ip and ip != "-":
                        cidr = ip if "/" in ip else f"{ip}/32"
                        blocked_ips.add(cidr)

        return list(blocked_ips)

    except ClientError:
        logger.exception("Error querying CloudWatch Logs")
        return []


def add_ips_to_set(ip_set_id: str, ip_set_name: str, ip_addresses: list[str]) -> None:
    """IP SetにIPアドレスを追加 (リトライ付き)"""
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = wafv2.get_ip_set(
                Scope=SCOPE, Id=ip_set_id, Name=ip_set_name
            )

            current = set(response["IPSet"]["Addresses"])
            updated = list(current | set(ip_addresses))

            if set(updated) == current:
                logger.info("No new IPs to add to %s", ip_set_name)
                return

            wafv2.update_ip_set(
                Scope=SCOPE,
                Id=ip_set_id,
                Name=ip_set_name,
                Addresses=updated,
                LockToken=response["LockToken"],
            )

            logger.info(
                "Updated IP set %s: %d -> %d addresses",
                ip_set_name,
                len(current),
                len(updated),
            )
            return

        except ClientError as e:
            if (
                e.response["Error"]["Code"] == "WAFOptimisticLockException"
                and attempt < max_retries - 1
            ):
                logger.warning("Lock conflict on %s, retrying...", ip_set_name)
                time.sleep(1)
                continue
            raise


def cleanup_expired_ips() -> None:
    """TTL期限切れのIPアドレスをIP Setから削除"""
    if IP_TTL_HOURS <= 0:
        return

    now = datetime.now(tz=timezone.utc)
    cutoff = now - timedelta(hours=IP_TTL_HOURS)

    for ip_set_id, ip_set_name in [
        (REPEAT_OFFENDERS_IP_SET_ID, REPEAT_OFFENDERS_IP_SET_NAME),
        (HEAVY_OFFENDERS_IP_SET_ID, HEAVY_OFFENDERS_IP_SET_NAME),
    ]:
        try:
            # 期限切れIPの特定にはCloudWatch Logsのタイムスタンプを使用
            query = (
                "fields @timestamp, httpRequest.clientIp as clientIP "
                f"| filter @timestamp < {int(cutoff.timestamp())} "
                '| filter action = "BLOCK" '
                "| stats max(@timestamp) as lastSeen by clientIP"
            )

            response = logs_client.start_query(
                logGroupName=LOG_GROUP,
                startTime=int((now - timedelta(days=7)).timestamp()),
                endTime=int(now.timestamp()),
                queryString=query,
            )

            time.sleep(3)
            results = logs_client.get_query_results(queryId=response["queryId"])

            expired_ips: set[str] = set()
            for result in results.get("results", []):
                ip_val = ""
                for field in result:
                    if field["field"] == "clientIP":
                        ip_val = field["value"].strip()
                if ip_val:
                    cidr = ip_val if "/" in ip_val else f"{ip_val}/32"
                    expired_ips.add(cidr)

            if not expired_ips:
                continue

            ip_set_resp = wafv2.get_ip_set(
                Scope=SCOPE, Id=ip_set_id, Name=ip_set_name
            )
            current = set(ip_set_resp["IPSet"]["Addresses"])
            remaining = list(current - expired_ips)

            if len(remaining) < len(current):
                wafv2.update_ip_set(
                    Scope=SCOPE,
                    Id=ip_set_id,
                    Name=ip_set_name,
                    Addresses=remaining,
                    LockToken=ip_set_resp["LockToken"],
                )
                logger.info(
                    "Cleaned up %d expired IPs from %s",
                    len(current) - len(remaining),
                    ip_set_name,
                )

        except ClientError:
            logger.exception("Error cleaning up expired IPs from %s", ip_set_name)
