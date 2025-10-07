import boto3
import json
import gzip
import base64
import os

def handler(event, context):
    """
    Processa logs do CloudWatch e inicia RDS quando detecta erro de conexão
    """
    rds_client = boto3.client('rds')
    db_instance_identifier = os.environ.get('DB_INSTANCE_IDENTIFIER', 'cloudfix')

    # Decodificar dados do CloudWatch Logs
    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)

    print(f"Processando {len(log_data['logEvents'])} eventos de log")

    # Padrões que indicam RDS indisponível (multilíngue)
    error_patterns = [
        "connection refused",
        "could not connect to server",
        "timeout expired",
        "server closed the connection unexpectedly",
        "psycopg2.operationalerror",
        "database connection failed",
        "rds unavailable",
        "conexão recusada",
        "não foi possível conectar",
        "timeout",
        "erro de conexão"
    ]

    connection_errors_found = 0

    # Analisar cada evento de log
    for log_event in log_data['logEvents']:
        message = log_event['message'].lower()

        # Verificar se contém padrões de erro de conexão
        for pattern in error_patterns:
            if pattern in message:
                connection_errors_found += 1
                print(f"Erro de conexão detectado: {pattern}")
                break

    if connection_errors_found > 0:
        print(f"Total de erros de conexão: {connection_errors_found}")

        try:
            # Verificar status atual da RDS
            response = rds_client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            current_status = response['DBInstances'][0]['DBInstanceStatus']

            print(f"Status atual da RDS: {current_status}")

            if current_status == 'stopped':
                print(f"🚀 Iniciando RDS {db_instance_identifier} devido a erros de conexão")

                rds_client.start_db_instance(DBInstanceIdentifier=db_instance_identifier)

                # Enviar notificação (opcional)
                send_notification(f"RDS {db_instance_identifier} foi iniciada automaticamente devido a tentativas de conexão")

                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'action': 'rds_started',
                        'reason': 'connection_errors_detected',
                        'errors_count': connection_errors_found
                    })
                }

            elif current_status in ['starting', 'available']:
                print(f"RDS já está {current_status}, não é necessário iniciar")
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'action': 'no_action_needed',
                        'reason': f'rds_already_{current_status}'
                    })
                }

            else:
                print(f"RDS está {current_status}, não pode ser iniciada")
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'action': 'cannot_start',
                        'reason': f'rds_status_{current_status}'
                    })
                }

        except Exception as e:
            print(f"Erro ao processar RDS: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'action': 'error',
                    'reason': str(e)
                })
            }

    else:
        print("Nenhum erro de conexão detectado nos logs")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'action': 'no_errors_found',
                'events_processed': len(log_data['logEvents'])
            })
        }

def send_notification(message):
    """
    Envia notificação (SNS, Slack, etc.) - opcional
    """
    try:
        # Exemplo com SNS (descomente se quiser usar)
        # sns = boto3.client('sns')
        # sns.publish(
        #     TopicArn='arn:aws:sns:us-east-1:123456789:rds-alerts',
        #     Message=message,
        #     Subject='RDS Auto-Start'
        # )
        print(f"Notificação: {message}")
    except Exception as e:
        print(f"Erro enviando notificação: {e}")
