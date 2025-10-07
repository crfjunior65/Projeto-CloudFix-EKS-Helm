#!/usr/bin/env bash
set -euo pipefail

# Versão simples e funcional para sincronizar chaves públicas locais para o bastion
# Uso mínimo: export BASTION_HOST/BASTION_USER/BASTION_SSH_KEY ou passe --host/--user/--ssh-key

# Defaults
KEYS_DIR="${KEYS_DIR:-${HOME}/.ssh/cloudfix-keys}"
BASTION_USER="${BASTION_USER:-ec2-user}"
BASTION_HOST="${BASTION_HOST:-}"
BASTION_NAME="${BASTION_NAME:-cloudfix-bastion-host-hml}"
BASTION_SSH_PORT="${BASTION_SSH_PORT:-22}"
# chave local padrão na pasta do repo / corrente
BASTION_SSH_KEY="${BASTION_SSH_KEY:-./aws-key-terraform.pem}"

# Flags
DRY_RUN=false
VERBOSE=false

usage() {
  cat <<EOF
Uso: $0 [--dry-run] [--verbose] [--dir DIR] [--user USER] [--host HOST] [--port PORT] [--ssh-key FILE]

Exemplo:
  BASTION_USER=ec2-user BASTION_HOST=34.12.34.56 $0 --verbose
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --dir) KEYS_DIR="$2"; shift 2 ;;
    --user) BASTION_USER="$2"; shift 2 ;;
    --host) BASTION_HOST="$2"; shift 2 ;;
    --port) BASTION_SSH_PORT="$2"; shift 2 ;;
    --ssh-key) BASTION_SSH_KEY="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Parâmetro desconhecido: $1"; usage ;;
  esac
done

log()   { if [[ "$VERBOSE" == true ]]; then printf '[%s] %s\n' "$(date +'%F %T')" "$*"; fi }
info()  { printf '[INFO] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

# Se host não fornecido, tentar resolver via AWS (tag Name = BASTION_NAME)
if [[ -z "$BASTION_HOST" ]]; then
  if command -v aws >/dev/null 2>&1; then
    info "🔍 Obtendo IP público do Bastion via AWS tag '$BASTION_NAME'..."
    BASTION_IP=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=$BASTION_NAME" "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[?PublicIpAddress!=null].PublicIpAddress' --output text 2>/dev/null || true)
    if [[ -n "$BASTION_IP" ]]; then
      BASTION_HOST="$BASTION_IP"
      info "Usando BASTION_HOST=$BASTION_HOST"
    else
      error "Não foi possível obter IP do bastion via AWS. Exporte BASTION_HOST ou verifique AWS CLI."
      exit 2
    fi
  else
    error "BASTION_HOST não definido e aws cli não encontrado. Exporte BASTION_HOST ou instale/configure aws cli."
    exit 2
  fi
fi

# Para evitar prompt de verificação de host em conexões automáticas,
# adicionamos a chave do host remota ao known_hosts local automaticamente.
# Só fazemos isso em execuções reais (não em --dry-run).
if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "${HOME}/.ssh"
  touch "${HOME}/.ssh/known_hosts"
  # se já existir um registro para o host/IP, não adicionar
  if ! grep -qF "${BASTION_HOST}" "${HOME}/.ssh/known_hosts" 2>/dev/null; then
    info "Adicionando chave do host ${BASTION_HOST} em ${HOME}/.ssh/known_hosts via ssh-keyscan"
    if ssh-keyscan -p "$BASTION_SSH_PORT" -H "$BASTION_HOST" >> "${HOME}/.ssh/known_hosts" 2>/dev/null; then
      chmod 644 "${HOME}/.ssh/known_hosts" || true
    else
      log "ssh-keyscan falhou para ${BASTION_HOST}; conexões SSH podem pedir verificação manual."
    fi
  else
    log "Host ${BASTION_HOST} já presente em ${HOME}/.ssh/known_hosts"
  fi
fi

# Validar diretório
if [[ ! -d "$KEYS_DIR" ]]; then
  error "Diretório de chaves não encontrado: $KEYS_DIR"
  exit 2
fi

# Coleta apenas arquivos .pub e nomes id_* (privadas podem ser ignoradas para evitar passphrases)
mapfile -t candidate_files < <(find "$KEYS_DIR" -maxdepth 1 -type f \( -name '*.pub' -o -name 'id_*' \) -print 2>/dev/null || true)

if [[ ${#candidate_files[@]} -eq 0 ]]; then
  info "Nenhuma chave pública encontrada em $KEYS_DIR"
  exit 0
fi

# Função para extrair a parte base64 da chave pública (campo 2)
extract_key_body() {
  # input: linha completa da chave, saída: campo 2 (base64)
  awk '{print $2}'
}

get_public_key_from_file() {
  local file="$1"
  if [[ "$file" == *.pub ]]; then
    # pega primeira linha não-vazia
    awk 'NF{print; exit}' "$file" | tr -d '\r'
    return 0
  fi
  # tenta gerar public key a partir da privada (não-interativo)
  if ssh-keygen -y -f "$file" >/dev/null 2>&1; then
    ssh-keygen -y -f "$file" | tr -d '\r'
    return 0
  fi
  return 1
}

for f in "${candidate_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi

  if ! pubkey=$(get_public_key_from_file "$f"); then
    log "Pulando $f — não é .pub ou não foi possível extrair pública."
    continue
  fi

  if ! printf '%s' "$pubkey" | grep -Eq '^(ssh-(rsa|dss|ed25519)|ecdsa-sha2-nistp)'; then
    log "Pulando $f — formato de chave pública inesperado."
    continue
  fi

  key_body=$(printf '%s' "$pubkey" | extract_key_body)
  if [[ -z "$key_body" ]]; then
    log "Pulando $f — não foi possível extrair corpo da chave."
    continue
  fi

  info "Processando $f"

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] iria sincronizar chave de $f para ${BASTION_USER}@${BASTION_HOST}"
    continue
  fi

  ssh_cmd=(ssh -i "$BASTION_SSH_KEY" -p "$BASTION_SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 "${BASTION_USER}@${BASTION_HOST}")
  log "Executando SSH: ${ssh_cmd[*]}"

  remote_payload=$(cat <<EOF
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# checar se já existe por corpo da chave (segundo campo)
if awk '{print \$2}' ~/.ssh/authorized_keys | grep -Fxq -- '${key_body}'; then
  echo "exists"
  exit 0
fi

cat >> ~/.ssh/authorized_keys <<'KEY'
${pubkey}
KEY
echo "added"
EOF
)

  if output="$("${ssh_cmd[@]}" bash -s <<< "$remote_payload" 2>&1)"; then
    info "Resultado remoto: $output"
  else
    error "Falha ao conectar/inserir chave '$f' em ${BASTION_HOST}:"
    printf '%s\n' "$output" >&2
  fi
done

info "Finalizado."
