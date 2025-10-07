#!/bin/bash

# Script para executar terraform destroy com medição de tempo
set -e

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Procedimentos do Terraform em: ${TIMESTAMP}"

echo "🚀 Iniciando Terraform..."
start_time=$(date +%s)

# Inicializando Terraform
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Terraform Destroy em: ${TIMESTAMP}"
# Capturar nome do cluster a partir do state ANTES do destroy para permitir waits posteriores
CLUSTER_NAME="$(terraform output -raw k8s_name 2>/dev/null || true)"
echo "🔎 Cluster name obtido do state (antes do destroy): ${CLUSTER_NAME:-<vazio>}"
# Remover addons EKS primeiro (evita travamento)
#aws eks delete-addon --cluster-name cloudfix-cluster --addon-name amazon-cloudwatch-observability --region us-east-1
#aws eks delete-addon --cluster-name cloudfix-cluster --addon-name aws-load-balancer-controller --region us-east-1
terraform destroy -auto-approve

# Nota: NÃO removemos os ficheiros de state imediatamente. Adiamos a limpeza até as checagens
# para que ainda possamos ler outputs ou para depuração caso algo falhe.
# Remoção de arquivos de state ficará para o final (ou manual)

end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Converter para formato legível
hours=$((execution_time / 3600))
minutes=$(( (execution_time % 3600) / 60 ))
seconds=$((execution_time % 60))

echo "✅ Terraform Destroy concluído!"
echo "⏱️  Tempo total de execução: ${hours}h ${minutes}m ${seconds}s"
echo "⏱️  Tempo em segundos: ${execution_time}s"

# --- NEW: waits to ensure infra is removed ---
WAIT_INTERVAL=${WAIT_INTERVAL:-10}
WAIT_CLUSTER_TIMEOUT=${WAIT_CLUSTER_TIMEOUT:-1800}
WAIT_NODEGROUP_TIMEOUT=${WAIT_NODEGROUP_TIMEOUT:-1800}
WAIT_INGRESS_TIMEOUT=${WAIT_INGRESS_TIMEOUT:-600}

wait_for_nodegroups_deleted() {
	local cluster_name="$1"
	local region="${AWS_REGION:-us-east-1}"
	local waited=0
	echo "⏳ Aguardando nodegroups do cluster ${cluster_name} serem removidos (timeout ${WAIT_NODEGROUP_TIMEOUT}s)..."
	while [ $waited -lt ${WAIT_NODEGROUP_TIMEOUT} ]; do
		ngs=$(aws eks list-nodegroups --cluster-name "${cluster_name}" --region "${region}" --output text 2>/dev/null || true)
		if [ -z "${ngs}" ]; then
			echo "✔ Nenhum nodegroup encontrado para ${cluster_name}"
			return 0
		fi
		echo "  Ainda existem nodegroups: ${ngs}. Aguardando ${WAIT_INTERVAL}s..."
		sleep ${WAIT_INTERVAL}
		waited=$((waited + WAIT_INTERVAL))
	done
	echo "❌ Timeout: nodegroups ainda existem após ${WAIT_NODEGROUP_TIMEOUT}s"
	return 1
}

wait_for_cluster_deleted() {
	local cluster_name="$1"
	local region="${AWS_REGION:-us-east-1}"
	local waited=0
	echo "⏳ Aguardando cluster ${cluster_name} ser removido (timeout ${WAIT_CLUSTER_TIMEOUT}s)..."
	while [ $waited -lt ${WAIT_CLUSTER_TIMEOUT} ]; do
		status=$(aws eks describe-cluster --name "${cluster_name}" --region "${region}" --query 'cluster.status' --output text 2>/dev/null || true)
		if [ -z "${status}" ]; then
			echo "✔ Cluster ${cluster_name} não encontrado (removido)."
			return 0
		fi
		echo "  Cluster status: ${status}. Aguardando ${WAIT_INTERVAL}s..."
		sleep ${WAIT_INTERVAL}
		waited=$((waited + WAIT_INTERVAL))
	done
	echo "❌ Timeout: cluster ${cluster_name} ainda existe após ${WAIT_CLUSTER_TIMEOUT}s"
	return 1
}

wait_for_ingress_deleted() {
	local ingress_name="$1"
	local namespace="$2"
	local waited=0
	if ! command -v kubectl >/dev/null 2>&1; then
		echo "⚠️  'kubectl' não disponível no runner — pulando checagem de Ingress"
		return 0
	fi
	echo "⏳ Aguardando Ingress ${ingress_name} no namespace ${namespace} ser removido (timeout ${WAIT_INGRESS_TIMEOUT}s)..."
	while [ $waited -lt ${WAIT_INGRESS_TIMEOUT} ]; do
		# Garantir kubeconfig caso o cluster ainda exista
		if [ -n "${CLUSTER_NAME}" ]; then
			aws eks update-kubeconfig --region "${AWS_REGION:-us-east-1}" --name "${CLUSTER_NAME}" || true
		fi
		exists=$(kubectl get ingress ${ingress_name} -n ${namespace} --ignore-not-found=true || true)
		if [ -z "${exists}" ]; then
			echo "✔ Ingress ${ingress_name} removido"
			return 0
		fi
		echo "  Ingress ainda existe. Aguardando ${WAIT_INTERVAL}s..."
		sleep ${WAIT_INTERVAL}
		waited=$((waited + WAIT_INTERVAL))
	done
	echo "❌ Timeout: ingress ${ingress_name} ainda existe após ${WAIT_INGRESS_TIMEOUT}s"
	return 1
}

CLUSTER_NAME="${CLUSTER_NAME:-}"
if [ "${TF_NONINTERACTIVE:-0}" = "1" ]; then
	if [ -n "${CLUSTER_NAME}" ]; then
		wait_for_nodegroups_deleted "${CLUSTER_NAME}" || echo "Aviso: nodegroups podem não ter sido totalmente removidos"
		wait_for_cluster_deleted "${CLUSTER_NAME}" || echo "Aviso: cluster pode não ter sido totalmente removido"
		# Optionally check ingress removal if manifests used
		TEST_INGRESS_NAME=${TEST_INGRESS_NAME:-test-lb-nginx-ingress}
		TEST_NAMESPACE=${TEST_NAMESPACE:-backoffice}
		wait_for_ingress_deleted "${TEST_INGRESS_NAME}" "${TEST_NAMESPACE}" || echo "Aviso: ingress pode não ter sido removido"
	else
		echo "⚠️  terraform output 'k8s_name' não disponível; pulando checagens de remoção EKS"
	fi
else
	echo "TF_NONINTERACTIVE!=1: pulando waits automáticos. Rode com TF_NONINTERACTIVE=1 para checagens automáticas."
fi

# Opcional: remover ficheiros de state local apenas se desejar (comentado por segurança)
# [ -e .terraform* ] && rm -rf .terraform* 2>/dev/null || true
# [ -e terraform.tfstate ] && rm -rf terraform.tfstate 2>/dev/null || true
# [ -e plan.out ] && rm -rf plan.out 2>/dev/null || true


# Salvar em arquivo de log
echo "$(date): Terraform iDestroy executado em ${execution_time} segundos" >> terraform_times.log
