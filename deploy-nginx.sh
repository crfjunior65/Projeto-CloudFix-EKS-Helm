#!/bin/bash

echo "Deploy automatizado do Nginx..."

# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name cloudfix-cluster

# Remover deployment antigo se existir
kubectl delete -f k8s/nginx-deployment.yaml --ignore-not-found=true

# Aplicar novo manifesto
kubectl apply -f k8s/nginx-complete.yaml

# Aguardar pods ficarem prontos
kubectl wait --for=condition=ready pod -l app=nginx --timeout=300s

# Verificar status
kubectl get pods -l app=nginx
kubectl get svc nginx-service
kubectl get ingress nginx-ingress

# Obter URL do ALB
sleep 30
ALB_URL=$(kubectl get ingress nginx-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ ! -z "$ALB_URL" ]; then
    echo "Nginx disponível em: http://$ALB_URL"
    curl -I "http://$ALB_URL" || echo "aguarde alguns minutos"
else
    echo "Provisionado, Rode: kubectl get ingress nginx-ingress"
fi
