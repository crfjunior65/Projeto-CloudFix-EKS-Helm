#!/bin/bash

# Script para executar terraform apply com medição de tempo
set -euo pipefail

# Support CI non-interactive mode via environment variables:
# TF_NONINTERACTIVE=1 -> do not prompt
# TF_APPLY_MANIFESTS=1 -> automatically apply k8s manifests after terraform
TF_NONINTERACTIVE=${TF_NONINTERACTIVE:-0}
TF_APPLY_MANIFESTS=${TF_APPLY_MANIFESTS:-0}

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Procedimentos do Terraform em: ${TIMESTAMP}"

echo "🚀 Iniciando Terraform..."
start_time=$(date +%s)

# Inicializando Terraform
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Terraform Init em: ${TIMESTAMP}"
terraform init -reconfigure
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Terraform Validate em: ${TIMESTAMP}"
terraform validate
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Terraform Farmat em: ${TIMESTAMP}"
terraform fmt --recursive

# Executar terraform apply
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "🕒 Iniciando Terraform Apply em: ${TIMESTAMP}"
# 2. Aplicar infraestrutura base (sem dashboard)
#terraform apply -target=module.vpc -target=module.rds -target=module.eks -auto-approve

# 3. Aguardar EKS estar pronto (5-10 minutos)
#aws eks update-kubeconfig --region us-east-1 --name cloudfix-cluster

# 4. Instalar Load Balancer Controller
#terraform apply -target=helm_release.aws_load_balancer_controller -auto-approve

# 5. Instalar CloudWatch Observability
#aws eks create-addon --cluster-name cloudfix-cluster --addon-name amazon-cloudwatch-observability --region us-east-1

# 6. DEPLOYMENTS DE APLICAÇÃO (AQUI!)
#kubectl apply -f k8s/  # Se tiver manifests K8s
# OU
#terraform apply -target=kubernetes_deployment.app -auto-approve  # Se estiver no Terraform

# Aguardar 3-5 minutos para métricas aparecerem
#sleep 250

# 7. Aplicar dashboard
#terraform apply -target=aws_cloudwatch_dashboard.cloudfix_dashboard_teste -auto-approve

# 8. Aplicar resto (se houver)
terraform apply -auto-approve

# Instalar CloudWatch Observability
#aws eks create-addon --cluster-name cloudfix-cluster --addon-name amazon-cloudwatch-observability --region us-east-1
# DEPLOYMENTS DE APLICAÇÃO (AQUI!)
# . Aguardar EKS estar pronto (5-10 minutos)
#aws eks update-kubeconfig --region us-east-1 --name cloudfix-cluster

# Instalar CloudWatch Agent
#kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

#kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

#kubectl apply -f k8s/  # Se tiver manifests K8s
# OU
#terraform apply -target=kubernetes_deployment.app -auto-approve  # Se estiver no Terraform

end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Converter para formato legível
hours=$((execution_time / 3600))
minutes=$(( (execution_time % 3600) / 60 ))
seconds=$((execution_time % 60))

echo "✅ Terraform Apply concluído!"
echo "⏱️  Tempo total de execução: ${hours}h ${minutes}m ${seconds}s"
echo "⏱️  Tempo em segundos: ${execution_time}s"

# Salvar em arquivo de log
echo "$(date): Terraform apply executado em ${execution_time} segundos" >> terraform_times.log
sleep 5

clear

echo "### **4. VERIFICAÇÕES FINAIS**"
echo "bash"
echo "# Verificar cluster"
echo ""
echo "Conectando no Cluster EKS:"
echo "✅ aws eks update-kubeconfig --region us-east-1 --name cloudfix-cluster ✅"
echo ""
echo "kubectl get nodes"
echo ""
echo "# Verificar addons"
echo "aws eks describe-addon --cluster-name cloudfix-cluster --addon-name amazon-cloudwatch-observability --region us-east-1"
echo ""
echo "# Verificar métricas (após 5 minutos)"
echo "aws cloudwatch list-metrics --namespace ContainerInsights --region us-east-1 | grep cloudfix-cluster"
echo ""
echo "# Verificar dashboard"
echo "aws cloudwatch get-dashboard --dashboard-name cloudfix-dashboard-funcional-completo --region us-east-1"
echo ""
echo "### **5. ORDEM CRÍTICA DE DEPENDÊNCIAS**"
echo "1. VPC → RDS → EKS (base)"
echo "2. Load Balancer Controller (Helm)"
echo "3. CloudWatch Addon (AWS CLI)"
echo "4. Dashboard (após métricas estarem disponíveis)"
echo ""
echo "⚠️ NUNCA pule a ordem ou aplique tudo junto na primeira vez!"

if [ "${TF_NONINTERACTIVE}" = "1" ]; then
    echo "TF_NONINTERACTIVE=1: não será solicitado input interativo. TF_APPLY_MANIFESTS=${TF_APPLY_MANIFESTS}"
    if [ "${TF_APPLY_MANIFESTS}" = "1" ]; then
        echo "Aplicando manifestos automaticamente (TF_APPLY_MANIFESTS=1)..."
        aws eks update-kubeconfig --region "${AWS_REGION:-us-east-1}" --name "$(terraform output -raw k8s_name)"
        kubectl apply -f k8s-manifests/ || true
    else
        echo "Pule a aplicação dos manifestos de configuração do Kubernetes (TF_APPLY_MANIFESTS!=1)."
    fi
else
    # Interactive fallback for manual runs
    read -p "Deseja aplicar os manifestos de configuração do Kubernetes agora? (s/n): " apply_manifests
    if [[ "$apply_manifests" == "s" || "$apply_manifests" == "S" ]]; then
        aws eks update-kubeconfig --region "${AWS_REGION:-us-east-1}" --name "$(terraform output -raw k8s_name)"
        echo "Aplicando manifestos de configuração do Kubernetes..."
        kubectl apply -f k8s-manifests/
        echo "Manifestos aplicados com sucesso."
    else
        echo "Pule a aplicação dos manifestos de configuração do Kubernetes."
    fi
fi

# --- NEW: waits to ensure infra fully ready (EKS, nodegroups, nodes, ingress) ---
# These waits run when TF_NONINTERACTIVE=1 (CI) so the workflow remains running until infra is ready.
WAIT_INTERVAL=${WAIT_INTERVAL:-10}           # seconds between polls
WAIT_CLUSTER_TIMEOUT=${WAIT_CLUSTER_TIMEOUT:-1800}   # seconds (default 30m)
WAIT_NODEGROUP_TIMEOUT=${WAIT_NODEGROUP_TIMEOUT:-1800}# seconds
WAIT_NODE_READY_TIMEOUT=${WAIT_NODE_READY_TIMEOUT:-900}# seconds (default 15m)
WAIT_INGRESS_TIMEOUT=${WAIT_INGRESS_TIMEOUT:-600}   # seconds (default 10m)

wait_for_cluster_active() {
    local cluster_name="$1"
    local region="${AWS_REGION:-us-east-1}"
    local waited=0
    echo "⏳ Aguardando cluster EKS '${cluster_name}' ficar ACTIVE (timeout ${WAIT_CLUSTER_TIMEOUT}s)..."
    while [ $waited -lt ${WAIT_CLUSTER_TIMEOUT} ]; do
        status=$(aws eks describe-cluster --name "${cluster_name}" --region "${region}" --query 'cluster.status' --output text 2>/dev/null || true)
        if [ "${status}" = "ACTIVE" ]; then
            echo "✔ Cluster ${cluster_name} está ACTIVE"
            return 0
        fi
        echo "Cluster status: ${status:-UNKNOWN} — aguardando ${WAIT_INTERVAL}s..."
        sleep ${WAIT_INTERVAL}
        waited=$((waited + WAIT_INTERVAL))
    done
    echo "❌ Timeout: cluster ${cluster_name} não ficou ACTIVE após ${WAIT_CLUSTER_TIMEOUT}s"
    return 1
}

wait_for_nodegroups_active() {
    local cluster_name="$1"
    local region="${AWS_REGION:-us-east-1}"
    local waited=0
    echo "⏳ Verificando nodegroups do cluster ${cluster_name} (timeout ${WAIT_NODEGROUP_TIMEOUT}s)..."
    # get nodegroups
    nodegroups=$(aws eks list-nodegroups --cluster-name "${cluster_name}" --region "${region}" --output text 2>/dev/null || true)
    if [ -z "${nodegroups}" ]; then
        echo "⚠️  Nenhum nodegroup encontrado (pode usar self-managed nodes). Pulando checagem de nodegroups."
        return 0
    fi
    for ng in ${nodegroups}; do
        echo "  - Aguardando nodegroup ${ng} ficar ACTIVE..."
        waited=0
        while [ $waited -lt ${WAIT_NODEGROUP_TIMEOUT} ]; do
            ng_status=$(aws eks describe-nodegroup --cluster-name "${cluster_name}" --nodegroup-name "${ng}" --region "${region}" --query 'nodegroup.status' --output text 2>/dev/null || true)
            if [ "${ng_status}" = "ACTIVE" ]; then
                echo "    ✔ Nodegroup ${ng} está ACTIVE"
                break
            fi
            echo "    nodegroup status: ${ng_status:-UNKNOWN} — aguardando ${WAIT_INTERVAL}s..."
            sleep ${WAIT_INTERVAL}
            waited=$((waited + WAIT_INTERVAL))
        done
        if [ $waited -ge ${WAIT_NODEGROUP_TIMEOUT} ]; then
            echo "❌ Timeout: nodegroup ${ng} não ficou ACTIVE após ${WAIT_NODEGROUP_TIMEOUT}s"
            return 1
        fi
    done
    return 0
}

wait_for_nodes_ready() {
    local cluster_name="$1"
    local region="${AWS_REGION:-us-east-1}"
    local waited=0
    if ! command -v kubectl >/dev/null 2>&1; then
        echo "⚠️  'kubectl' não disponível no runner — pulando checagem de nodes via kubectl"
        return 0
    fi
    echo "⏳ Atualizando kubeconfig e aguardando nodes Ready (timeout ${WAIT_NODE_READY_TIMEOUT}s)..."
    aws eks update-kubeconfig --region "${region}" --name "${cluster_name}" || true
    while [ $waited -lt ${WAIT_NODE_READY_TIMEOUT} ]; do
        not_ready_count=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' | grep -v Ready | wc -l || true)
        total_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || true)
        if [ -z "${total_count}" ] || [ "${total_count}" -eq 0 ]; then
            echo "  Nenhum node listado ainda. Aguardando ${WAIT_INTERVAL}s..."
        else
            if [ "${not_ready_count}" -eq 0 ]; then
                echo "✔ Todos os ${total_count} nodes estão Ready"
                return 0
            else
                echo "  Nodes não prontos: ${not_ready_count}/${total_count}. Aguardando ${WAIT_INTERVAL}s..."
            fi
        fi
        sleep ${WAIT_INTERVAL}
        waited=$((waited + WAIT_INTERVAL))
    done
    echo "❌ Timeout: nem todos os nodes ficaram Ready após ${WAIT_NODE_READY_TIMEOUT}s"
    kubectl get nodes -o wide || true
    return 1
}

wait_for_ingress_hostname() {
    local ingress_name="$1"
    local namespace="$2"
    local waited=0
    if ! command -v kubectl >/dev/null 2>&1; then
        echo "⚠️  'kubectl' não disponível no runner — pulando checagem de Ingress/ALB"
        return 0
    fi
    echo "⏳ Aguardando Ingress ${ingress_name} em namespace ${namespace} ter hostname (timeout ${WAIT_INGRESS_TIMEOUT}s)..."
    while [ $waited -lt ${WAIT_INGRESS_TIMEOUT} ]; do
        HOST=$(kubectl get ingress ${ingress_name} -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
        if [ -n "${HOST}" ]; then
            echo "✔ Ingress hostname: ${HOST}"
            return 0
        fi
        echo "  hostname ainda vazio. Aguardando ${WAIT_INTERVAL}s..."
        sleep ${WAIT_INTERVAL}
        waited=$((waited + WAIT_INTERVAL))
    done
    echo "❌ Timeout: Ingress ${ingress_name} não recebeu hostname após ${WAIT_INGRESS_TIMEOUT}s"
    kubectl describe ingress ${ingress_name} -n ${namespace} || true
    return 1
}

if [ "${TF_NONINTERACTIVE}" = "1" ]; then
    # get cluster name from terraform output if available
    CLUSTER_NAME="$(terraform output -raw k8s_name 2>/dev/null || true)"
    if [ -n "${CLUSTER_NAME}" ]; then
        if ! wait_for_cluster_active "${CLUSTER_NAME}"; then
            echo "Aviso: cluster não atingiu estado ACTIVE dentro do timeout"
        else
            if ! wait_for_nodegroups_active "${CLUSTER_NAME}"; then
                echo "Aviso: algum nodegroup não ficou ACTIVE dentro do timeout"
            else
                wait_for_nodes_ready "${CLUSTER_NAME}" || echo "Aviso: nodes não ficaram totalmente prontos"
            fi
        fi
    else
        echo "⚠️  terraform output 'k8s_name' não disponível; pulando checagens de EKS"
    fi

    # If manifests were applied, wait for test ingress (name chosen in CI manifests)
    if [ "${TF_APPLY_MANIFESTS}" = "1" ]; then
        # Ingress name and namespace used in repo manifests
        TEST_INGRESS_NAME=${TEST_INGRESS_NAME:-test-lb-nginx-ingress}
        TEST_NAMESPACE=${TEST_NAMESPACE:-backoffice}
        wait_for_ingress_hostname "${TEST_INGRESS_NAME}" "${TEST_NAMESPACE}" || echo "Aviso: ingress/ALB pode não ter sido criado"
    fi
fi

# --- end waits ---
