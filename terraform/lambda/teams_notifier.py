import json
import urllib3
import os
from datetime import datetime

def handler(event, context):
    webhook_url = os.environ.get('TEAMS_WEBHOOK_URL')
    
    if not webhook_url:
        print("Teams webhook URL not configured")
        return {'statusCode': 200}
    
    try:
        # Parse SNS message
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = sns_message.get('AlarmName', 'Unknown')
        new_state = sns_message.get('NewStateValue', 'Unknown')
        reason = sns_message.get('NewStateReason', 'No reason provided')
        
        # Create Teams message
        color = "FF0000" if new_state == "ALARM" else "00FF00"
        
        teams_message = {
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "themeColor": color,
            "summary": f"WAF Alert: {alarm_name}",
            "sections": [{
                "activityTitle": "🛡️ AWS WAF Alert",
                "activitySubtitle": f"Alarm: {alarm_name}",
                "facts": [
                    {"name": "Status", "value": new_state},
                    {"name": "Reason", "value": reason},
                    {"name": "Time", "value": datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}
                ]
            }]
        }
        
        # Send to Teams
        http = urllib3.PoolManager()
        response = http.request(
            'POST',
            webhook_url,
            body=json.dumps(teams_message),
            headers={'Content-Type': 'application/json'}
        )
        
        print(f"Teams notification sent: {response.status}")
        return {'statusCode': 200}
        
    except Exception as e:
        print(f"Error sending Teams notification: {str(e)}")
        return {'statusCode': 500}
