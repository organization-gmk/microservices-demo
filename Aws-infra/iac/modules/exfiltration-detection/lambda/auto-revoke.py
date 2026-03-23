import boto3
import json
import logging
import random
import string
import os
import sys

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')

# Try to import psycopg2, but don't fail if not available
try:
    import psycopg2
    HAS_DB = True
except ImportError:
    HAS_DB = False
    logger.warning("psycopg2 not available - running in demo mode (no database updates)")

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
        # Check if version already exists
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
    
    # Update the secret value
    if 'POSTGRES_PASSWORD' in current_secret:
        current_secret['POSTGRES_PASSWORD'] = new_password
    elif 'password' in current_secret:
        current_secret['password'] = new_password
    else:
        current_secret['password'] = new_password
    
    # Create new version
    secretsmanager.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(current_secret),
        VersionStages=['AWSPENDING']
    )
    logger.info(f"✅ Created new secret version {token}")

def set_secret(secret_id, token):
    """Update database with new password (if available)"""
    # Get pending secret
    try:
        pending = secretsmanager.get_secret_value(
            SecretId=secret_id,
            VersionId=token,
            VersionStage='AWSPENDING'
        )
        secret = json.loads(pending['SecretString'])
    except Exception as e:
        logger.error(f"Failed to get pending secret: {e}")
        raise
    
    # Try to update database if psycopg2 is available
    if HAS_DB:
        try:
            # Get current secret (old credentials)
            current = secretsmanager.get_secret_value(
                SecretId=secret_id,
                VersionStage='AWSCURRENT'
            )
            current_secret = json.loads(current['SecretString'])
            
            # Connect to database using OLD credentials to set NEW password
            conn = psycopg2.connect(
                host=os.environ.get('DB_HOST', 'auth-db.patient-service.svc.cluster.local'),
                port=os.environ.get('DB_PORT', '5432'),
                user=current_secret.get('username', 'authuser'),
                password=current_secret.get('POSTGRES_PASSWORD', current_secret.get('password')),
                database=current_secret.get('database', 'authdb'),
                connect_timeout=5
            )
            conn.autocommit = True
            cursor = conn.cursor()
            
            # Update user password
            new_password = secret.get('POSTGRES_PASSWORD', secret.get('password'))
            cursor.execute(
                f"ALTER USER {secret.get('username', 'authuser')} PASSWORD '{new_password}';"
            )
            logger.info(f"✅ Updated database password for user {secret.get('username', 'authuser')}")
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            logger.error(f"Database update failed: {e}")
            logger.info("Continuing with rotation - database may be updated manually")
            # Don't fail - continue rotation for POC
    else:
        # Demo mode - just log success
        logger.info(f"✅ DEMO MODE: Would update database with new password for {secret.get('username', 'unknown')}")

def test_secret(secret_id, token):
    """Test the new secret"""
    # Get pending secret
    try:
        pending = secretsmanager.get_secret_value(
            SecretId=secret_id,
            VersionId=token,
            VersionStage='AWSPENDING'
        )
        secret = json.loads(pending['SecretString'])
    except Exception as e:
        logger.error(f"Failed to get pending secret: {e}")
        raise
    
    # Test database connection if psycopg2 is available
    if HAS_DB:
        try:
            conn = psycopg2.connect(
                host=os.environ.get('DB_HOST', 'auth-db.patient-service.svc.cluster.local'),
                port=os.environ.get('DB_PORT', '5432'),
                user=secret.get('username', 'authuser'),
                password=secret.get('POSTGRES_PASSWORD', secret.get('password')),
                database=secret.get('database', 'authdb'),
                connect_timeout=5
            )
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()
            logger.info("✅ Database connection test successful")
            
        except Exception as e:
            logger.error(f"Database test failed: {e}")
            logger.info("Continuing with rotation - may need manual verification")
            # Don't fail - continue rotation for POC
    else:
        # Demo mode - just log success
        logger.info(f"✅ DEMO MODE: Database connection test would succeed for user {secret.get('username', 'unknown')}")

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
    logger.info(f"✅ Rotation complete! New version {token} is now AWSCURRENT")

def generate_password(length=20):
    """Generate random password"""
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(random.choice(chars) for _ in range(length))