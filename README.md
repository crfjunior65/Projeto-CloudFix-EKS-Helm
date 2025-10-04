<<<<<<< HEAD
# Plataforma ClouFix — Repositório
=======
# Projeto CloudFix — Repositório
>>>>>>> 4c2e13d (Primeiro commit)

Este repositório contém automações, manifests Kubernetes e scripts Terraform para provisionamento e gestão de uma plataforma (EKS, ALB, RDS, ECR, etc.). Este README entrega um guia prático para configurar, testar e operar os workflows e scripts que existem aqui.

## Visão geral

- Infraestrutura: código e scripts em `terraform/`.
- Manifests Kubernetes: `k8s/`.
- Workflows GitHub Actions: `.github/workflows/` (CI, validações e automação de infra).
- Scripts auxiliares: `terraform-aws/UpTerraform.sh`, `terraform-aws/DwnTerraform.sh` (há backups `.bak`).

## Estrutura principal (resumo)

- `.github/workflows/main.yaml` — CI principal (build de imagens, push para ECR, testes básicos). Consulte o arquivo para detalhes.
- `.github/workflows/eks-validate.yml` — workflow manual para validar que o Ingress criou um ALB (faz polling e coleta artefatos).
- `.github/workflows/infra-up.yml` — workflow manual para subir infra usando `UpTerraform.sh` (usa `environment: infrastructure`).
- `.github/workflows/infra-destroy.yml` — workflow manual para destruir infra com `DwnTerraform.sh`.
- `terraform-aws/UpTerraform.sh` — script que embala o `terraform apply` e opcionalmente aplica manifests k8s. Suporta execução não interativa via `TF_NONINTERACTIVE=1`.

## Pré-requisitos

- Conta AWS com permissões para criar recursos (EKS, ALB, EC2, ECR, IAM, RDS). Recomenda-se ter um role para CI (OIDC) ou chaves com permissões mínimas.
- GitHub repository admin access para configurar `Environments` e `Secrets`.
- Locally: `terraform`, `kubectl`, `aws` CLI e `docker` (para testes/lint locais).

## Configuração recomendada no GitHub

1. Criar um Environment chamado `infrastructure` em Settings → Environments.
2. Em `infrastructure` adicionar os secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - (opcional) `AWS_REGION` — caso não informe, os workflows usam `us-east-1` como default.
3. Configurar reviewers obrigatórios para esse environment (protege operações de infra).

Observação de segurança: o ideal é usar OIDC e `assume-role` no lugar de armazenar chaves no repositório. Ver `Próximas mudanças` abaixo.

## Como executar localmente os scripts Terraform

1. Faça o checkout e posicione-se na pasta do repo.

2. Exportar variáveis de ambiente para testar em local (exemplo zsh):

```bash
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
```

3. Rodar `UpTerraform.sh` em modo não interativo (execução de CI):

```bash
cd terraform-aws
chmod +x UpTerraform.sh
TF_NONINTERACTIVE=1 TF_APPLY_MANIFESTS=true ./UpTerraform.sh | tee up-terraform.log
```

4. Para destruir:

```bash
cd terraform-aws
chmod +x DwnTerraform.sh
./DwnTerraform.sh | tee dwn-terraform.log
```

OBS: Existem backups `UpTerraform.sh.bak` e `DwnTerraform.sh.bak` no mesmo diretório caso precise reverter.

## Como executar os workflows no GitHub

- Infra Up (manual): Actions → Infra Up → Run workflow. Escolha `apply_manifests: true|false`.
- Infra Destroy (manual): Actions → Infra Destroy → Run workflow.
- EKS Validate (manual): Actions → EKS Validate → Run workflow (fará polling e tentará localizar o ALB criado pelo Ingress).

Os workflows usam o Environment `infrastructure` — então crie/posicione os secrets nesse environment para que a execução seja permitida e segura.

## Comportamento e modos de erro (pontos importantes)

- `UpTerraform.sh` em modo não interativo falhará se o backend do Terraform não for acessível ou se as credenciais não tiverem permissão de escrita. Verifique `terraform-aws/up-terraform.log` (uploadado como artefato no workflow).
- Se o step de `configure-aws-credentials` falhar, valide se os secrets existem e se o region está setado. Preferível mover secrets para o Environment.
- Erros ao aplicar manifests k8s normalmente se devem a problemas de kubeconfig (o script assume que o cluster EKS foi criado e que o kubeconfig é atualizado pelo terraform output). Em CI, confirme que `kubectl` consegue conectar ao cluster antes de aplicar.

<!-- BEGIN_TF_DOCS -->
# 🚀 Terraform AWS EKS Project

## 📝 Project Overview

This project provides a robust and scalable infrastructure for running containerized applications on AWS usi
ng
Terraform. It provisions a complete EKS (Elastic Kubernetes Service) cluster with all the necessary componen
ts,
including networking, database, load balancing, and monitoring.

**Please replace this section with a more detailed description of your project's goals and use case.**

---

## 🏗️ Architecture

The infrastructure is composed of the following main components:

*   🌐 **Networking**: A custom VPC with public and private subnets to ensure a secure and isolated environm
ent for
    the different resources.

*   ⚙️ **Amazon EKS (Elastic Kubernetes Service)**: A managed Kubernetes service to deploy, manage, and scale
    containerized applications.

*   🗃️ **Amazon RDS (Relational Database Service)**: A managed relational database for the applications, conf
igured
    for high availability and scalability.

*   ⚖️ **Application Load Balancer (ALB)**: To distribute incoming traffic across the applications running in
 the
    EKS cluster.

*   📈 **Monitoring & Observability**: Integration with Amazon CloudWatch, including Container Insights and
custom
    dashboards, for monitoring the health and performance of the cluster and applications.

For a more detailed view, please refer to the diagrams in the `diagramas/` directory.

---

## 🌱 Project Evolution

This section should describe the history and evolution of the project. You can include information about maj
or
milestones, versions, and future plans.

**Example:**

*   **v1.0 (2023-01-15):** Initial version of the project, with the basic EKS cluster and networking setup.
*   **v1.1 (2023-02-20):** Added RDS integration and the monitoring module.
*   **v2.0 (2023-04-10):** Major refactoring, introduced modules for better organization and reusability.

---

## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
# Projeto-CloudFix-EKS-Helm
