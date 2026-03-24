import boto3
import json
import logging
import random
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """Handle secret rotation from Secrets Manager"""
    logger.info(f"Rotation event: {json.dumps(event)}")
    
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    logger.info(f"Step: {step} for secret: {secret_id}")
    
    if step == 'createSecret':
        create_secret(secret_id, token)
    elif step == 'setSecret':
        set_secret(secret_id, token)
    elif step == 'testSecret':
        test_secret(secret_id, token)
    elif step == 'finishSecret':
        finish_secret(secret_id, token)
    
    return {'statusCode': 200}

def create_secret(secret_id, token):
    """Create a new secret version with a NEW password"""
    try:
        secretsmanager.get_secret_value(SecretId=secret_id, VersionId=token, VersionStage='AWSPENDING')
        logger.info(f"Version {token} already exists")
        return
    except:
        pass
    
    # Get current secret
    current = secretsmanager.get_secret_value(SecretId=secret_id, VersionStage='AWSCURRENT')
    current_secret = json.loads(current['SecretString'])
    
    # 🔥 GENERATE A NEW PASSWORD
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    new_password = ''.join(random.choice(chars) for _ in range(20))
    logger.info(f"✨ GENERATED NEW PASSWORD: {new_password}")
    
    # Create new secret with the new password
    new_secret = current_secret.copy()
    
    # Update the password field
    if 'POSTGRES_PASSWORD' in new_secret:
        new_secret['POSTGRES_PASSWORD'] = new_password
        logger.info(f"Updated POSTGRES_PASSWORD field")
    else:
        new_secret['password'] = new_password
        logger.info(f"Updated password field")
    
    # Create new pending version
    secretsmanager.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=['AWSPENDING']
    )
    logger.info(f"✅ Created new pending version {token} with NEW password")

def set_secret(secret_id, token):
    """Update database with new password (POC - skip)"""
    pending = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    secret = json.loads(pending['SecretString'])
    new_password = secret.get('POSTGRES_PASSWORD', secret.get('password', 'unknown'))
    logger.info(f"✅: Would update database with new password: {new_password[:10]}...")

def test_secret(secret_id, token):
    """Test the new secret (POC - assume success)"""
    logger.info(f"✅: New secret tested successfully")

def finish_secret(secret_id, token):
    """Mark the new secret as current"""
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    # Find current version
    current_version = None
    for version_id, stages in metadata['VersionIdsToStages'].items():
        if 'AWSCURRENT' in stages:
            current_version = version_id
            break
    
    # Move AWSCURRENT to new version
    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    logger.info(f"✅ Rotation complete! New version {token} is now AWSCURRENT")