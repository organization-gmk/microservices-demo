"""
Auto-Revocation Lambda for Secret Exfiltration Detection
Triggered by CloudWatch Alarm via SNS
"""

import boto3
import json
import logging
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
secretsmanager = boto3.client('secretsmanager')
sns = boto3.client('sns')
cloudtrail = boto3.client('cloudtrail')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main handler for auto-revocation Lambda
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse SNS message from CloudWatch alarm
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = sns_message.get('AlarmName', 'unknown')
        alarm_reason = sns_message.get('NewStateReason', 'unknown')
        alarm_timestamp = sns_message.get('StateChangeTime', datetime.utcnow().isoformat())
        
        logger.info(f"Alarm triggered: {alarm_name}")
        logger.info(f"Reason: {alarm_reason}")
        
        # Get secrets accessed in last 15 minutes
        affected_secrets = get_recently_accessed_secrets(minutes=15)
        
        if not affected_secrets:
            logger.info("No secrets accessed in last 15 minutes")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No secrets to revoke'})
            }
        
        logger.info(f"Found {len(affected_secrets)} potentially compromised secrets")
        
        # Revoke each secret
        revoked = []
        failed = []
        
        for secret_arn in affected_secrets:
            result = revoke_secret(secret_arn, alarm_name)
            if result['success']:
                revoked.append(result)
            else:
                failed.append(result)
        
        # Send summary notification
        send_summary_notification(alarm_name, alarm_reason, revoked, failed)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'alarm': alarm_name,
                'revoked_count': len(revoked),
                'failed_count': len(failed),
                'revoked_details': revoked,
                'failed_details': failed,
                'timestamp': datetime.utcnow().isoformat()
            }, indent=2)
        }
        
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}", exc_info=True)
        
        # Send error notification
        send_error_notification(str(e), event)
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def get_recently_accessed_secrets(minutes: int = 15) -> List[str]:
    """
    Query CloudTrail for secrets accessed in last X minutes
    """
    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=minutes)
        
        logger.info(f"Querying CloudTrail from {start_time} to {end_time}")
        
        response = cloudtrail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'EventName',
                    'AttributeValue': 'GetSecretValue'
                }
            ],
            StartTime=start_time,
            EndTime=end_time,
            MaxResults=100
        )
        
        secret_arns = set()
        user_map = {}
        
        for event in response.get('Events', []):
            username = event.get('Username', 'unknown')
            event_time = event.get('EventTime')
            
            for resource in event.get('Resources', []):
                if resource.get('ResourceType') == 'AWS::SecretsManager::Secret':
                    secret_arn = resource.get('ResourceName')
                    secret_arns.add(secret_arn)
                    
                    # Track which users accessed which secrets
                    if secret_arn not in user_map:
                        user_map[secret_arn] = []
                    user_map[secret_arn].append({
                        'user': username,
                        'time': str(event_time)
                    })
        
        # Log details for debugging
        for secret_arn in secret_arns:
            users = user_map.get(secret_arn, [])
            logger.info(f"Secret {secret_arn} accessed by: {users}")
        
        return list(secret_arns)
        
    except Exception as e:
        logger.error(f"Error querying CloudTrail: {str(e)}", exc_info=True)
        return []

def revoke_secret(secret_arn: str, alarm_name: str) -> Dict[str, Any]:
    """
    Revoke a compromised secret by forcing immediate rotation
    """
    result = {
        'secret_arn': secret_arn,
        'success': False,
        'action': None,
        'error': None
    }
    
    try:
        # Extract secret name from ARN
        secret_name = secret_arn.split(':')[-1].replace('secret:', '')
        
        logger.info(f"Attempting to revoke secret: {secret_name}")
        
        # Check if DRY_RUN_MODE is enabled
        if os.environ.get('DRY_RUN_MODE', 'false').lower() == 'true':
            logger.info(f"DRY RUN: Would revoke {secret_name}")
            result['action'] = 'dry_run'
            result['success'] = True
            return result
        
        # Get current secret metadata
        secret_info = secretsmanager.describe_secret(SecretId=secret_name)
        
        # Check if rotation is already enabled
        rotation_enabled = secret_info.get('RotationEnabled', False)
        
        if rotation_enabled:
            # Force immediate rotation
            response = secretsmanager.rotate_secret(
                SecretId=secret_name,
                RotationRules={
                    'AutomaticallyAfterDays': 1
                }
            )
            result['action'] = 'rotated'
            logger.info(f"✅ Rotated secret: {secret_name}")
        else:
            # Enable rotation with immediate effect
            response = secretsmanager.rotate_secret(
                SecretId=secret_name,
                RotationRules={
                    'AutomaticallyAfterDays': 1
                }
            )
            result['action'] = 'enabled_and_rotated'
            logger.info(f"✅ Enabled rotation and rotated: {secret_name}")
        
        result['success'] = True
        
        # Send individual alert for this secret
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"🔐 SECURITY: Secret Auto-Revoked - {alarm_name}",
            Message=json.dumps({
                'alarm': alarm_name,
                'secret': secret_name,
                'secret_arn': secret_arn,
                'action': result['action'],
                'timestamp': datetime.utcnow().isoformat(),
                'message': f"Secret {secret_name} has been automatically revoked due to exfiltration detection"
            }, indent=2)
        )
        
    except Exception as e:
        error_msg = f"Failed to revoke {secret_arn}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        result['error'] = str(e)
    
    return result

def send_summary_notification(alarm_name: str, alarm_reason: str, 
                             revoked: List[Dict], failed: List[Dict]) -> None:
    """
    Send summary notification of revocation actions
    """
    try:
        message = {
            'alarm': alarm_name,
            'alarm_reason': alarm_reason,
            'timestamp': datetime.utcnow().isoformat(),
            'summary': {
                'total_revoked': len(revoked),
                'total_failed': len(failed)
            },
            'revoked_secrets': revoked,
            'failed_secrets': failed,
            'response_time_seconds': calculate_response_time()
        }
        
        # Send to SNS
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"📊 Auto-Revocation Summary - {alarm_name}",
            Message=json.dumps(message, indent=2)
        )
        
        logger.info("Summary notification sent")
        
    except Exception as e:
        logger.error(f"Failed to send summary: {str(e)}")

def send_error_notification(error: str, event: Dict) -> None:
    """
    Send error notification when Lambda fails
    """
    try:
        message = {
            'error': error,
            'timestamp': datetime.utcnow().isoformat(),
            'event': event,
            'severity': 'HIGH'
        }
        
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="❌ Auto-Revocation Lambda Failed",
            Message=json.dumps(message, indent=2)
        )
        
    except Exception as e:
        logger.error(f"Failed to send error notification: {str(e)}")

def calculate_response_time() -> float:
    """
    Calculate response time from alarm trigger to revocation
    """
    # This would need CloudWatch metrics integration
    # Placeholder for now
    return 0.0

# For local testing
if __name__ == "__main__":
    # Test event
    test_event = {
        "Records": [
            {
                "Sns": {
                    "Message": json.dumps({
                        "AlarmName": "test-alarm",
                        "NewStateReason": "Test reason",
                        "StateChangeTime": datetime.utcnow().isoformat()
                    })
                }
            }
        ]
    }
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2))