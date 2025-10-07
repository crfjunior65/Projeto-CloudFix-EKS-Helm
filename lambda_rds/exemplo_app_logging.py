#!/usr/bin/env python3
"""
Exemplo de como sua aplicação deve logar para ativar o auto-start
"""
import logging
import psycopg2
import time

# Configurar logging para CloudWatch
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
logger = logging.getLogger(__name__)

def conectar_banco_com_auto_start():
    """
    Conecta no banco com retry automático via logs
    """
    max_retries = 3
    retry_delay = 180  # 3 minutos (tempo para RDS iniciar)

    for attempt in range(max_retries):
        try:
            logger.info(f"Tentativa {attempt + 1} de conexão com RDS")

            conn = psycopg2.connect(
                host="cloudfix.cybw0osiizjg.us-east-1.rds.amazonaws.com",
                database="cloudfix",
                user="postgres",
                password="sua_senha",
                port=5432,
                connect_timeout=10
            )

            logger.info("✅ Conectado ao RDS com sucesso")
            return conn

        except psycopg2.OperationalError as e:
            error_msg = str(e).lower()

            if any(pattern in error_msg for pattern in [
                "connection refused",
                "timeout expired",
                "server closed the connection"
            ]):
                # Log específico que ativa a Lambda
                logger.error(f"ERROR connection failed to RDS: {e}")
                logger.info(f"RDS pode estar parada. Aguardando auto-start...")

                if attempt < max_retries - 1:
                    logger.info(f"Aguardando {retry_delay} segundos antes da próxima tentativa")
                    time.sleep(retry_delay)
                else:
                    logger.error("Máximo de tentativas atingido")
                    return None
            else:
                logger.error(f"Erro de conexão não relacionado ao RDS: {e}")
                return None

        except Exception as e:
            logger.error(f"Erro inesperado: {e}")
            return None

    return None

def exemplo_uso_na_aplicacao():
    """
    Como integrar na sua aplicação
    """
    logger.info("🚀 Iniciando aplicação Plataforma Bet")

    # Tentar conectar (com auto-start automático)
    conexao = conectar_banco_com_auto_start()

    if conexao:
        try:
            cursor = conexao.cursor()
            cursor.execute("SELECT COUNT(*) FROM pg_stat_activity")
            result = cursor.fetchone()
            logger.info(f"Conexões ativas no banco: {result[0]}")

        except Exception as e:
            logger.error(f"Erro executando query: {e}")
        finally:
            conexao.close()
            logger.info("Conexão fechada")
    else:
        logger.error("❌ Não foi possível conectar ao banco")

if __name__ == "__main__":
    exemplo_uso_na_aplicacao()
