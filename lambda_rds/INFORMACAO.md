### Renato estou trabalhando para ligar sob demanda de acesso..... Segue Abaixo um Breve Inforação para funcionammento

### RDS Scheduler Lambda

Projeto Terraform para automatizar start/stop da instância RDS "postgres" usando Lambda e EventBridge.

## 🎯 Funcionalidades

- **Start automático**: 07:00 (horário de Brasília) - Segunda a Domingo
- **Stop automático**: 19:00 (horário de Brasília) - Segunda a Domingo
- **Economia de custos**: RDS fica ligado apenas 12h por dia
- **Segurança**: Policy IAM restrita apenas à instância "db-RDS"

## 📋 Recursos Criados

- **Lambda Function**: `RDSScheduler` (Python 3.12)
- **IAM Role/Policy**: Permissões específicas para RDS
- **EventBridge Rules**: Agendamento automático
- **CloudWatch Logs**: Monitoramento das execuções

## 🚀 Deploy

```bash
# Validar configuração
terraform validate

# Ver plano de execução
terraform plan

# Aplicar mudanças
terraform apply
```

## 🔧 Configuração

- **Instância RDS**: `postgres` (descoberta automaticamente via data source)
- **Timezone**: America/Sao_Paulo (UTC-3)
- **Runtime**: Python 3.12
- **Timeout**: 60 segundos

## 📊 Monitoramento

Logs disponíveis no CloudWatch:
- `/aws/lambda/RDSScheduler`

## 💰 Economia Estimada

- **Antes**: RDS 24h/dia = ~$8.76/mês (db.t3.micro)
- **Depois**: RDS 12h/dia = ~$4.38/mês
- **Economia**: ~50% nos custos de RDS

---

lambda_rds/
├── provider.tf              # Configuração AWS/Terraform
├── main.tf                  # Agendamento (EventBridge + Lambda)
├── log_monitor.tf           # Auto-start (CloudWatch + Lambda)
├── lambda_function.py       # Código agendamento
├── log_monitor_function.py  # Código auto-start
├── terraform.tfvars         # Variáveis personalizadas
└── DOCUMENTACAO_COMPLETA.md # Documentação completa

## 🚀 Procedimentos:
