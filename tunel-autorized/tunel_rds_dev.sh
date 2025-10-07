#!/bin/bash

# Script para devs - Tunnel RDS sem gerenciar chave SSH

RDS_DB_NAME="postgres"
BASTION_NAME="cloudfix-hml-bastion-host"
SSH_KEY=$1

# Obter IP do Bastion
#"Add Ip Publico elasticoou dns do Bastion-host"
BASTION_IP=3.220.103.33
#$(aws ec2 describe-instances \
#    --filters "Name=tag:Name,Values=$BASTION_NAME" "Name=instance-state-name,Values=running" \
#    --query 'Reservations[].Instances[].[PublicIpAddress]' \
#    --output text)

# Obter endpoint RDS
RDS_ENDPOINT=postgres.c6b2o0m2kb9j.us-east-1.rds.amazonaws.com
#$(aws rds describe-db-instances \
#    --db-instance-identifier "$RDS_DB_NAME" \
#    --query 'DBInstances[0].Endpoint.Address' \
#    --output text)

echo "🚀 Tunnel: localhost:5435 → $RDS_ENDPOINT:5432"
echo "💡 Conecte: psql -h localhost -p 5435 -U cloudfix -d cloudfix"

# Tunnel usando a chave do terraform
ssh -N -L 5435:$RDS_ENDPOINT:5432 \
    ec2-user@$BASTION_IP \
    -i "$SSH_KEY" \
    -o ServerAliveInterval=60
