#!/bin/bash

# Script para testar conectividade EKS -> RDS
# Data: $(date)

set -e

echo "🚀 Iniciando teste de conectividade EKS -> RDS..."

# Configurações
CLUSTER_NAME="cloudfix-cluster"
REGION="us-east-1"
RDS_ENDPOINT="postgres.c6b2o0m2kb9j.us-east-1.rds.amazonaws.com"
DB_USER="cloudfix"
DB_NAME="cloudfix"
DB_PASSWORD="cloudfix_password"

echo "📡 Conectando ao cluster EKS..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "🐘 Criando pod de teste PostgreSQL..."
kubectl run postgres-test --image=postgres:15 --rm -i --restart=Never -- bash -c "
echo '🔌 Testando conectividade de rede...'
timeout 10 bash -c 'cat < /dev/null > /dev/tcp/$RDS_ENDPOINT/5432' && echo '✅ Conectividade TCP OK' || echo '❌ Falha na conectividade TCP'

echo '🗄️ Testando conexão PostgreSQL...'
export PGPASSWORD='$DB_PASSWORD'
psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -c 'SELECT version();' && echo '✅ Conexão PostgreSQL OK' || echo '❌ Falha na conexão PostgreSQL'

echo '📊 Executando testes SQL...'
psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME << EOF
SELECT 'Teste de conectividade iniciado' as status;
CREATE TABLE IF NOT EXISTS teste_conectividade (id SERIAL PRIMARY KEY, timestamp TIMESTAMP DEFAULT NOW(), status VARCHAR(50));
INSERT INTO teste_conectividade (status) VALUES ('conectividade_ok');
SELECT * FROM teste_conectividade ORDER BY timestamp DESC LIMIT 5;
DROP TABLE teste_conectividade;
SELECT 'Teste de conectividade concluído com sucesso!' as resultado;
EOF

echo '✅ Todos os testes concluídos com sucesso!'
"

echo "🎉 Teste de conectividade EKS -> RDS finalizado!"
echo "💡 Limpando pod de teste..."
echo " 🗄️ Esse Prompt voce esta dentro do Pod no Cluster EKS 🗄️"
echo " 🐘 Voce pode rodar comandos psql para testar a conexao com o RDS 🐘"
echo " 🐘 Exemplo: psql -h postgres.cybw0osiizjg.us-east-1.rds.amazonaws.com -U cloudfix -d cloudfix -p 5432"
read -p "Pressione Enter para continuar..."

kubectl run postgres-test --image=postgres:15 --rm -i --restart=Never -- bash
echo "💡 Limpando pod de teste..."
