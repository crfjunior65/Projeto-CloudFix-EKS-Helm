import boto3
import os
import json
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Starts or stops an RDS instance based on the 'action' in the event payload.
    Integrado com o projeto PBet - PostgreSQL RDS
    """
    db_instance_identifier = os.environ.get('DB_INSTANCE_IDENTIFIER', 'postgres')
    action = event.get('action')

    logger.info(f"Event received: {json.dumps(event)}")
    logger.info(f"DB Instance: {db_instance_identifier}, Action: {action}")

    # Validação de parâmetros
    if not db_instance_identifier:
        error_msg = 'Error: DB_INSTANCE_IDENTIFIER environment variable not set.'
        logger.error(error_msg)
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': error_msg})
        }

    if action not in ['start', 'stop']:
        error_msg = f"Error: Invalid action '{action}'. Must be 'start' or 'stop'."
        logger.error(error_msg)
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': error_msg})
        }

    rds_client = boto3.client('rds')

    try:
        # Verificar se a instância existe
        try:
            response = rds_client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instance = response['DBInstances'][0]
            current_status = db_instance['DBInstanceStatus']
            engine = db_instance['Engine']

            logger.info(f"Found RDS instance: {db_instance_identifier}")
            logger.info(f"Engine: {engine}, Current status: {current_status}")

        except rds_client.exceptions.DBInstanceNotFoundFault:
            error_msg = f'RDS instance {db_instance_identifier} not found'
            logger.error(error_msg)
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': error_msg})
            }

        # Processar ação START
        if action == 'start':
            if current_status == 'available':
                message = f'RDS instance {db_instance_identifier} is already running (status: {current_status})'
                logger.info(message)
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': message,
                        'instance': db_instance_identifier,
                        'status': current_status,
                        'action': 'start',
                        'result': 'already_running'
                    })
                }
            elif current_status == 'stopped':
                logger.info(f"Starting RDS instance: {db_instance_identifier}")
                rds_client.start_db_instance(DBInstanceIdentifier=db_instance_identifier)
                message = f'Successfully initiated start for {db_instance_identifier}'
                logger.info(message)

                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': message,
                        'instance': db_instance_identifier,
                        'previous_status': current_status,
                        'action': 'start',
                        'result': 'initiated'
                    })
                }
            else:
                message = f'Cannot start RDS instance {db_instance_identifier}. Current status: {current_status}'
                logger.warning(message)
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'error': message,
                        'instance': db_instance_identifier,
                        'status': current_status,
                        'action': 'start'
                    })
                }

        # Processar ação STOP
        elif action == 'stop':
            if current_status == 'stopped':
                message = f'RDS instance {db_instance_identifier} is already stopped (status: {current_status})'
                logger.info(message)
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': message,
                        'instance': db_instance_identifier,
                        'status': current_status,
                        'action': 'stop',
                        'result': 'already_stopped'
                    })
                }
            elif current_status == 'available':
                logger.info(f"Stopping RDS instance: {db_instance_identifier}")
                rds_client.stop_db_instance(DBInstanceIdentifier=db_instance_identifier)
                message = f'Successfully initiated stop for {db_instance_identifier}'
                logger.info(message)

                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'message': message,
                        'instance': db_instance_identifier,
                        'previous_status': current_status,
                        'action': 'stop',
                        'result': 'initiated'
                    })
                }
            else:
                message = f'Cannot stop RDS instance {db_instance_identifier}. Current status: {current_status}'
                logger.warning(message)
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'error': message,
                        'instance': db_instance_identifier,
                        'status': current_status,
                        'action': 'stop'
                    })
                }

    except Exception as e:
        error_msg = f'Unexpected error processing instance {db_instance_identifier}: {str(e)}'
        logger.error(error_msg, exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': error_msg,
                'instance': db_instance_identifier,
                'action': action
            })
        }
