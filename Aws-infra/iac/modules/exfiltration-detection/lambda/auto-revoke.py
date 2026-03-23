import boto3
import json
import logging
import random
import string
import psycopg2
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')
rds = boto3.client('rds')

def lambda_handler(event, context):
    """Handle secret rotation from Secrets Manager"""
    logger.info(f"Rotation event: {json.dumps(event)}")
    
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    if step == 'createSecret':
        create_secret(secret_id, token)
    elif step == 'setSecret':
        set_secret(secret_id, token)
    elif step == 'testSecret':
        test_secret(secret_id, token)
    elif step == 'finishSecret':
        finish_secret(secret_id, token)
    else:
        raise ValueError(f"Invalid step: {step}")

def create_secret(secret_id, token):
    """Create a new secret version"""
    try:
        secretsmanager.get_secret_value(
            SecretId=secret_id,
            VersionId=token,
            VersionStage='AWSPENDING'
        )
        logger.info(f"Secret version {token} already exists")
        return
    except secretsmanager.exceptions.ResourceNotFoundException:
        pass
    
    # Get current secret
    current = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionStage='AWSCURRENT'
    )
    current_secret = json.loads(current['SecretString'])
    
    # Generate new password
    new_password = generate_password()
    
    # Create new secret with updated password
    new_secret = current_secret.copy()
    
    # Update password field - handle both formats
    if 'POSTGRES_PASSWORD' in new_secret:
        new_secret['POSTGRES_PASSWORD'] = new_password
    elif 'password' in new_secret:
        new_secret['password'] = new_password
    else:
        # Add password if not present
        new_secret['password'] = new_password
    
    # Create new version
    secretsmanager.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=['AWSPENDING']
    )
    logger.info(f"Created new secret version {token}")

def set_secret(secret_id, token):
    """Update the database with new password"""
    # Get pending secret
    pending = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    secret = json.loads(pending['SecretString'])
    
    # Get current secret (old credentials)
    current = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionStage='AWSCURRENT'
    )
    current_secret = json.loads(current['SecretString'])
    
    # Connect to PostgreSQL using CURRENT credentials to update to PENDING password
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST', 'auth-db.patient-service.svc.cluster.local'),
            port=os.environ.get('DB_PORT', '5432'),
            user=current_secret.get('username', 'authuser'),
            password=current_secret.get('POSTGRES_PASSWORD', current_secret.get('password')),
            database=current_secret.get('database', 'authdb')
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
        # Update user password
        new_password = secret.get('POSTGRES_PASSWORD', secret.get('password'))
        cursor.execute(
            f"ALTER USER {secret.get('username', 'authuser')} PASSWORD '{new_password}';"
        )
        logger.info(f"Updated password for user {secret.get('username', 'authuser')}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        logger.error(f"Failed to update database: {str(e)}")
        raise e

def test_secret(secret_id, token):
    """Test the new secret by connecting to database"""
    # Get pending secret
    pending = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    secret = json.loads(pending['SecretString'])
    
    # Test connection with new credentials
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST', 'auth-db.patient-service.svc.cluster.local'),
            port=os.environ.get('DB_PORT', '5432'),
            user=secret.get('username', 'authuser'),
            password=secret.get('POSTGRES_PASSWORD', secret.get('password')),
            database=secret.get('database', 'authdb')
        )
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        logger.info("Test connection successful")
        
    except Exception as e:
        logger.error(f"Test connection failed: {str(e)}")
        raise e

def finish_secret(secret_id, token):
    """Mark the new secret as current"""
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    current_version = None
    for version_id, stages in metadata['VersionIdsToStages'].items():
        if 'AWSCURRENT' in stages:
            current_version = version_id
            break
    
    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    logger.info(f"Finished rotation: {token} is now AWSCURRENT")

def generate_password(length=20):
    """Generate random password"""
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(random.choice(chars) for _ in range(length))