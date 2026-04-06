"""
WAF Fail2ban Slack Notifier Lambda
- SNS → Lambda でSlack通知を送信
- Block Kitフォーマット対応
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Any

import urllib3


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    channel = os.environ.get("SLACK_CHANNEL", "aws_system_notify")

    try:
        sns_message = json.loads(event["Records"][0]["Sns"]["Message"])

        alarm_name = sns_message.get("AlarmName", "Unknown")
        alarm_desc = sns_message.get("AlarmDescription", "No description")
        new_state = sns_message.get("NewStateValue", "Unknown")
        reason = sns_message.get("NewStateReason", "No reason provided")
        timestamp = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        color = {
            "ALARM": "danger",
            "OK": "good",
        }.get(new_state, "warning")

        slack_message = {
            "channel": f"#{channel}",
            "username": "AWS WAF Alert",
            "icon_emoji": ":shield:",
            "attachments": [
                {
                    "color": color,
                    "title": f"WAF Alert: {alarm_name}",
                    "text": alarm_desc,
                    "fields": [
                        {"title": "Status", "value": new_state, "short": True},
                        {"title": "Time", "value": timestamp, "short": True},
                        {"title": "Reason", "value": reason[:500], "short": False},
                    ],
                    "footer": "AWS WAFv2 Fail2ban System",
                }
            ],
        }

        http = urllib3.PoolManager()
        response = http.request(
            "POST",
            webhook_url,
            body=json.dumps(slack_message),
            headers={"Content-Type": "application/json"},
        )

        print(f"Slack notification sent: {response.status}")
        return {"statusCode": 200}

    except Exception as e:
        print(f"Error sending Slack notification: {e}")
        return {"statusCode": 500}
