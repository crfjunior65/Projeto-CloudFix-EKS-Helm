#!/bin/bash

echo "🔐 Configurando acesso de usuários ao EKS..."

# Obter ARN do role criado
EKS_VIEWER_ROLE_ARN=$(terraform output -raw eks_viewer_role_arn)

# Substituir placeholder no ConfigMap
sed "s/\${eks_viewer_role_arn}/$EKS_VIEWER_ROLE_ARN/g" k8s-manifests/aws-auth-configmap.yaml > /tmp/aws-auth-configmap.yaml

# Aplicar ConfigMap aws-auth
echo "📝 Aplicando ConfigMap aws-auth..."
kubectl apply -f /tmp/aws-auth-configmap.yaml

# Aplicar RBAC
echo "🔑 Aplicando RBAC..."
kubectl apply -f k8s-manifests/eks-viewer-rbac.yaml

# Verificar configuração
echo "✅ Verificando configuração..."
kubectl get configmap aws-auth -n kube-system -o yaml
kubectl get clusterrole eks-viewer
kubectl get clusterrolebinding eks-viewer

echo "🎉 Configuração concluída!"
echo ""
echo "📋 Para usar o acesso:"
echo "1. Usuário deve assumir o role: $EKS_VIEWER_ROLE_ARN"
echo "2. Configurar kubectl: aws eks update-kubeconfig --region us-east-1 --name $(terraform output -raw k8s_name) --role-arn $EKS_VIEWER_ROLE_ARN"
echo "3. Testar acesso: kubectl get pods --all-namespaces"

# Limpar arquivo temporário
rm -f /tmp/aws-auth-configmap.yaml
