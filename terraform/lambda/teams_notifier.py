"""
WAF Fail2ban Teams Notifier Lambda
- SNS → Lambda でMicrosoft Teams通知を送信
- Adaptive Card フォーマット対応 (MessageCard非推奨のため移行)
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Any

import urllib3


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    webhook_url = os.environ.get("TEAMS_WEBHOOK_URL")

    if not webhook_url:
        print("Teams webhook URL not configured")
        return {"statusCode": 200}

    try:
        sns_message = json.loads(event["Records"][0]["Sns"]["Message"])
        alarm_name = sns_message.get("AlarmName", "Unknown")
        new_state = sns_message.get("NewStateValue", "Unknown")
        reason = sns_message.get("NewStateReason", "No reason provided")
        timestamp = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        color = "attention" if new_state == "ALARM" else "good"

        # Adaptive Card format (Teams Workflows対応)
        teams_message = {
            "type": "message",
            "attachments": [
                {
                    "contentType": "application/vnd.microsoft.card.adaptive",
                    "content": {
                        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                        "type": "AdaptiveCard",
                        "version": "1.4",
                        "body": [
                            {
                                "type": "TextBlock",
                                "text": "🛡️ AWS WAF Alert",
                                "weight": "bolder",
                                "size": "large",
                                "style": "heading",
                            },
                            {
                                "type": "FactSet",
                                "facts": [
                                    {"title": "Alarm", "value": alarm_name},
                                    {"title": "Status", "value": new_state},
                                    {"title": "Time", "value": timestamp},
                                    {"title": "Reason", "value": reason[:200]},
                                ],
                            },
                        ],
                    },
                }
            ],
        }

        http = urllib3.PoolManager()
        response = http.request(
            "POST",
            webhook_url,
            body=json.dumps(teams_message),
            headers={"Content-Type": "application/json"},
        )

        print(f"Teams notification sent: {response.status}")
        return {"statusCode": 200}

    except Exception as e:
        print(f"Error sending Teams notification: {e}")
        return {"statusCode": 500}
