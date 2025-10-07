````markdown
# Plataforma-Bet — Repositório

Este repositório contém automações, manifests Kubernetes e scripts Terraform para provisionamento e gestão de uma plataforma (EKS, ALB, RDS, ECR, etc.). Este README entrega um guia prático para configurar, testar e operar os workflows e scripts que existem aqui.

## Visão geral

- Infraestrutura: código e scripts em `terraform-aws/`.
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
# Plataforma-Bet — Repositório

Este repositório contém automações, manifests Kubernetes e scripts Terraform para provisionamento e gestão de uma plataforma (EKS, ALB, RDS, ECR, etc.). Este README entrega um guia prático para configurar, testar e operar os workflows e scripts que existem aqui.

## Visão geral

- Infraestrutura: código e scripts em `terraform-aws/`.
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

## Troubleshooting rápido

- 401/erro de push para ECR: verifique se o nome do tag usado é totalmente qualificado (registry/account.dkr.ecr.<region>.amazonaws.com/repo:tag) e o login ECR foi realizado com sucesso.
- Linter/validator reclamando de `secrets.*` nos workflows: mova as chaves para o Environment `infrastructure` ou use OIDC (assume-role).
- Timeout em polling do ALB (eks-validate): o Ingress pode demorar; aumente o timeout no workflow se necessário.

## Próximas mudanças recomendadas (prioridade alta → baixa)

1. Harden dos workflows com OIDC e assume-role (alta): remover chaves estáticas e configurar trust policy. Isto melhora segurança e é a prática recomendada.
2. Adicionar checks de Terraform no CI: `terraform fmt`, `terraform validate` e `terraform plan` em PRs (média): evita drift e erros de sintaxe antes do apply.
3. Validação de manifests Kubernetes no CI (média): adicionar `kubeconform`/`kubeval`/`kubectl --dry-run=client` antes de aplicar manifests.
4. Propagar `project_prefix`/`name_prefix` na raiz do Terraform e garantir que todos módulos o recebam (alta): facilita ambientes múltiplos e nomes previsíveis.
5. Melhorar logs e retry/backoff nos scripts de polling e nas steps sensíveis (baixa): adicionar retry logic mais robusta e upload estruturado de logs em JSON/text para análise.

Cada item acima está listado também no TODO do repositório (veja `X.Analise-IA-03092025` e o arquivo de tarefas dentro deste projeto).

## Como contribuir

- Para mudanças nos workflows, abra um Pull Request contra `main`. Se a mudança envolver infra, solicite revisão de um maintainer com permissão para o Environment `infrastructure`.
- Para testes locais de Terraform, rode `terraform init` e `terraform validate` na pasta `terraform-aws` antes de enviar PR.

## Contato/Notas finais

- Se quiser, posso aplicar as próximas mudanças automaticamente: por exemplo migrar os workflows para OIDC/assume-role ou adicionar checks de Terraform no CI. Diga qual item da lista acima prefere que eu comece e eu atualizo o TODO e aplico as mudanças.
