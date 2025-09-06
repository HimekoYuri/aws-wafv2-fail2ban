import json
import urllib3
import os

def handler(event, context):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    # Parse SNS message
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    
    alarm_name = sns_message.get('AlarmName', 'Unknown')
    alarm_description = sns_message.get('AlarmDescription', 'No description')
    new_state = sns_message.get('NewStateValue', 'Unknown')
    reason = sns_message.get('NewStateReason', 'No reason provided')
    
    # Determine color based on alarm state
    color = "danger" if new_state == "ALARM" else "good" if new_state == "OK" else "warning"
    
    # Create Slack message
    slack_message = {
        "attachments": [
            {
                "color": color,
                "title": f"WAF Alert: {alarm_name}",
                "text": alarm_description,
                "fields": [
                    {
                        "title": "State",
                        "value": new_state,
                        "short": True
                    },
                    {
                        "title": "Reason",
                        "value": reason,
                        "short": False
                    }
                ],
                "footer": "AWS WAFv2 Fail2ban",
                "ts": int(context.aws_request_id.split('-')[0], 16) if context else None
            }
        ]
    }
    
    # Send to Slack
    http = urllib3.PoolManager()
    response = http.request(
        'POST',
        webhook_url,
        body=json.dumps(slack_message),
        headers={'Content-Type': 'application/json'}
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Message sent to Slack')
    }
