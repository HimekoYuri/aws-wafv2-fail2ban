import json
import boto3
import os
from datetime import datetime, timedelta
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

wafv2 = boto3.client('wafv2')
cloudwatch = boto3.client('cloudwatch')

# 環境変数
REPEAT_OFFENDERS_IP_SET_ID = os.environ['REPEAT_OFFENDERS_IP_SET_ID']
HEAVY_OFFENDERS_IP_SET_ID = os.environ['HEAVY_OFFENDERS_IP_SET_ID']
REPEAT_OFFENDERS_IP_SET_NAME = os.environ['REPEAT_OFFENDERS_IP_SET_NAME']
HEAVY_OFFENDERS_IP_SET_NAME = os.environ['HEAVY_OFFENDERS_IP_SET_NAME']
SCOPE = 'CLOUDFRONT'

def handler(event, context):
    """
    CloudWatch AlarmからのトリガーでIP管理を実行
    """
    try:
        # SNSメッセージの解析
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = sns_message.get('AlarmName', '')
        new_state = sns_message.get('NewStateValue', '')
        
        logger.info(f"Processing alarm: {alarm_name}, state: {new_state}")
        
        if new_state == 'ALARM':
            if 'Stage2' in alarm_name:
                # Stage2でブロックされたIPを再犯者リストに追加
                handle_repeat_offender(sns_message)
            elif 'Stage3' in alarm_name:
                # Stage3でブロックされたIPを重度犯罪者リストに追加
                handle_heavy_offender(sns_message)
        
        return {
            'statusCode': 200,
            'body': json.dumps('IP management completed successfully')
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise

def handle_repeat_offender(sns_message):
    """
    再犯者リストにIPを追加
    """
    try:
        # CloudWatch Logsから最近ブロックされたIPを取得
        blocked_ips = get_recently_blocked_ips('Stage2LightBlockRule')
        
        if blocked_ips:
            add_ips_to_set(REPEAT_OFFENDERS_IP_SET_ID, REPEAT_OFFENDERS_IP_SET_NAME, blocked_ips)
            logger.info(f"Added {len(blocked_ips)} IPs to repeat offenders list")
            
    except Exception as e:
        logger.error(f"Error handling repeat offender: {str(e)}")

def handle_heavy_offender(sns_message):
    """
    重度犯罪者リストにIPを追加
    """
    try:
        # CloudWatch Logsから最近ブロックされたIPを取得
        blocked_ips = get_recently_blocked_ips('Stage3RepeatOffenderRule')
        
        if blocked_ips:
            add_ips_to_set(HEAVY_OFFENDERS_IP_SET_ID, HEAVY_OFFENDERS_IP_SET_NAME, blocked_ips)
            logger.info(f"Added {len(blocked_ips)} IPs to heavy offenders list")
            
    except Exception as e:
        logger.error(f"Error handling heavy offender: {str(e)}")

def get_recently_blocked_ips(rule_name):
    """
    CloudWatch Logsから最近ブロックされたIPアドレスを取得
    """
    try:
        logs_client = boto3.client('logs')
        
        # 過去5分間のログを検索
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=5)
        
        query = f'''
        fields @timestamp, clientIP
        | filter action = "BLOCK"
        | filter terminatingRuleId = "{rule_name}"
        | stats count() by clientIP
        | sort count desc
        '''
        
        response = logs_client.start_query(
            logGroupName='/aws/wafv2/fail2ban',
            startTime=int(start_time.timestamp()),
            endTime=int(end_time.timestamp()),
            queryString=query
        )
        
        query_id = response['queryId']
        
        # クエリ結果を取得
        import time
        time.sleep(2)  # クエリ完了を待機
        
        results = logs_client.get_query_results(queryId=query_id)
        
        blocked_ips = []
        for result in results.get('results', []):
            for field in result:
                if field['field'] == 'clientIP':
                    ip = field['value']
                    if ip and ip != '-':
                        blocked_ips.append(f"{ip}/32")
        
        return list(set(blocked_ips))  # 重複除去
        
    except Exception as e:
        logger.error(f"Error getting blocked IPs: {str(e)}")
        return []

def add_ips_to_set(ip_set_id, ip_set_name, ip_addresses):
    """
    IP SetにIPアドレスを追加
    """
    try:
        # 現在のIP Setを取得
        response = wafv2.get_ip_set(
            Scope=SCOPE,
            Id=ip_set_id,
            Name=ip_set_name
        )
        
        current_addresses = set(response['IPSet']['Addresses'])
        new_addresses = set(ip_addresses)
        
        # 新しいIPアドレスのみを追加
        updated_addresses = list(current_addresses.union(new_addresses))
        
        # IP Setを更新
        wafv2.update_ip_set(
            Scope=SCOPE,
            Id=ip_set_id,
            Name=ip_set_name,
            Addresses=updated_addresses,
            LockToken=response['LockToken']
        )
        
        logger.info(f"Successfully updated IP set {ip_set_name} with {len(new_addresses)} new IPs")
        
    except Exception as e:
        logger.error(f"Error updating IP set: {str(e)}")
        raise

def cleanup_expired_ips():
    """
    期限切れのIPアドレスをIP Setから削除
    （将来の拡張用）
    """
    # TODO: DynamoDBと連携して期限管理を実装
    pass