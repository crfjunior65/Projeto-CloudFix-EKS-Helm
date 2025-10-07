#!/bin/bash

# Script: add-key-to-bastion.sh
# Descrição: Cria novo par de chaves e adiciona ao Bastion Host usando chave de acesso existente

set -e  # Sai imediatamente em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# CONFIGURAÇÕES

cp -rf ../terraform-aws/aws-key-terraform.pem .

RDS_DB_NAME="postgres"
BASTION_NAME="cloudfix-hml-bastion-host"
SSH_KEY="./aws-key-terraform.pem"

# Obter IP Publico do Bastion
echo "🔍 Obtendo IP Publico do Bastion '$BASTION_NAME'..."
BASTION_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$BASTION_NAME" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[PublicIpAddress]' \
    --output text)


# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

# Verificar parâmetros
if [ $# -lt 1 ]; then
    echo "Uso: $0 <nome-nova-chave> <e-mail>"
    echo "Exemplo: $0 nova-chave-bastion renato@goritek.com"
    exit 1
fi

EMAIL="$2"
EXISTING_KEY="./aws-key-terraform.pem"  # Chave de acesso existente
NEW_KEY_NAME="cloudfix-$1"
USER="${3:-ec2-user}"  # Padrão: ec2-user

KEY_DIR="${HOME}/.ssh/cloudfix-keys"
NEW_PRIVATE_KEY="${KEY_DIR}/${NEW_KEY_NAME}.pem"
NEW_PUBLIC_KEY="${KEY_DIR}/${NEW_KEY_NAME}.pub"
echo "$NEW_PRIVATE_KEY --- $NEW_PUBLIC_KEY"
echo "------------------------------------------------------------------"
# Configurações SSH
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Verificar se a chave de acesso existe
check_existing_key() {
    if [ ! -f "$EXISTING_KEY" ]; then
        error "Chave de acesso não encontrada: $EXISTING_KEY"
    fi

    if [ ! -s "$EXISTING_KEY" ]; then
        error "Chave de acesso está vazia: $EXISTING_KEY"
    fi

    # Verificar se a chave é válida
    if ! ssh-keygen -l -f "$EXISTING_KEY" &> /dev/null; then
        error "Chave de acesso inválida: $EXISTING_KEY"
    fi

    log "Chave de acesso válida: $EXISTING_KEY"
}

# Verificar conectividade com o bastion
test_bastion_connection() {
    log "Testando conectividade com o Bastion Host usando chave existente..."

    if ! ssh $SSH_OPTS -i "$EXISTING_KEY" "${USER}@${BASTION_IP}" "echo '# Conexão SSH bem-sucedida'" &> /dev/null; then
        error "Não foi possível conectar ao Bastion Host com a chave fornecida"
    fi

    log "Conectividade com Bastion Host: OK"
}

# Criar novo par de chaves
create_new_key_pair() {
    log "Criando novo par de chaves SSH..."

    # Criar diretório se não existir
    mkdir -p "${KEY_DIR}"
    chmod 770 "${KEY_DIR}"

    if [ -f "${NEW_PRIVATE_KEY}" ]; then
        warn "Chave privada já existe: ${NEW_PRIVATE_KEY}"
        read -p "Deseja sobrescrever? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log "Usando chave existente."
            return
        fi
        rm -f "${NEW_PRIVATE_KEY}" "${NEW_PUBLIC_KEY}"
    fi

    # Criar nova chave
    ssh-keygen -t rsa -b 4096 -f "${NEW_PRIVATE_KEY}" -N "" -C "bastion-${NEW_KEY_NAME}-${EMAIL}" -q
    #ssh-keygen -t rsa -b 4096 -f "${NEW_PRIVATE_KEY}" -N "" -C "bastion-${NEW_KEY_NAME}-$(date +%Y%m%d)" -q

    if [ $? -eq 0 ]; then
        log "# Novo par de chaves criado:"
        log "   - Privada: ${NEW_PRIVATE_KEY}"
        log "   - Pública: ${NEW_PUBLIC_KEY}"

        mv "${NEW_PRIVATE_KEY}.pub" "${NEW_PUBLIC_KEY}"

        echo "Conteúdo da pasta $KEY_DIR:"
        ls -lha "${KEY_DIR}"
        # Ajustar permissões
        echo "Ajustando permissões..."
        #chmod 600 "${NEW_PRIVATE_KEY}"
        #chmod 644 "${NEW_PUBLIC_KEY}"
        chmod 600 "${NEW_PRIVATE_KEY}"
        chmod 644 "${NEW_PUBLIC_KEY}"
        log "# Permissões ajustadas."
    else
        error "Falha ao criar novo par de chaves"
    fi
}

# Adicionar nova chave pública ao authorized_keys do bastion
add_key_to_bastion() {
    log "Adicionando nova chave pública ao Bastion Host..."

    # Ler o conteúdo da chave pública
    local new_key_content
    new_key_content=$(cat "${NEW_PUBLIC_KEY}")

    # Comando para executar no bastion
    local remote_cmd="
        set -e
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys

        # Verificar se a chave já existe
        if grep -qF '${new_key_content}' ~/.ssh/authorized_keys; then
            echo '##  Chave já existe no authorized_keys'
        else
            echo '${new_key_content}' >> ~/.ssh/authorized_keys
            echo '# Nova chave adicionada ao authorized_keys'
        fi

        # Verificar resultado
        echo '*** Total de chaves autorizadas:'
        wc -l ~/.ssh/authorized_keys
        echo '** Últimas chaves adicionadas:'
        tail -5 ~/.ssh/authorized_keys | cut -d' ' -f3-
    "

    # Executar no bastion
    if ssh $SSH_OPTS -i "$EXISTING_KEY" "${USER}@${BASTION_IP}" "$remote_cmd"; then
        log "# Chave pública adicionada com sucesso ao Bastion Host"
    else
        error "Falha ao adicionar chave pública ao Bastion Host"
    fi
}

# Testar conexão com a nova chave
test_new_key_connection() {
    log "Testando conexão com a nova chave..."

    # Aguardar um pouco para garantir que as alterações foram processadas
    sleep 2

    if ssh $SSH_OPTS -i "${NEW_PRIVATE_KEY}" "${USER}@${BASTION_IP}" "echo '# Conexão com nova chave bem-sucedida!'"; then
        log "# Nova chave funcionando corretamente"
    else
        warn "###  Nova chave ainda não está funcionando (pode levar alguns segundos)"
        warn "Tente novamente em alguns instantes com:"
        warn "  ssh -i ${NEW_PRIVATE_KEY} ${USER}@${BASTION_IP}"
    fi
}

# Criar entrada no SSH config
create_ssh_config_entry() {
    local ssh_config="${HOME}/.ssh/config"
    local config_entry="
Host bastion-${NEW_KEY_NAME}
    HostName ${BASTION_IP}
    User ${USER}
    IdentityFile ${NEW_PRIVATE_KEY}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10"

    # Backup do arquivo config se existir
    if [ -f "${ssh_config}" ]; then
        cp "${ssh_config}" "${ssh_config}.backup.$(date +%Y%m%d)"
    fi

    # Adicionar entrada se não existir
    if ! grep -q "Host bastion-${NEW_KEY_NAME}" "${ssh_config}" 2>/dev/null; then
        echo -e "\n${config_entry}" >> "${ssh_config}"
        chmod 600 "${ssh_config}"
        log "# Entrada adicionada ao ~/.ssh/config"
    else
        log "##  Entrada já existe no ~/.ssh/config"
    fi
}

# Função principal
main() {
    log "Iniciando configuração automática do Bastion Host..."
    log "Bastion IP: ${BASTION_IP}"
    log "Chave de acesso: ${EXISTING_KEY}"
    log "Nova chave: ${NEW_KEY_NAME}"
    log "Usuário: ${USER}"

    check_existing_key
    test_bastion_connection
    create_new_key_pair
    add_key_to_bastion
    test_new_key_connection
    create_ssh_config_entry

    display_summary
}

# Exibir resumo
display_summary() {
    echo
    log "=== CONFIGURAÇÃO CONCLUÍDA COM SUCESSO ==="
    log "Bastion Host: ${BASTION_IP}"
    log "Chave de acesso usada: ${EXISTING_KEY}"
    log "Nova chave privada: ${NEW_PRIVATE_KEY}"
    log "Nova chave pública: ${NEW_PUBLIC_KEY}"
    log "Usuário: ${USER}"
    echo
    log "--- Comandos úteis:"
    log "   Conectar: ssh bastion-${NEW_KEY_NAME}"
    log "   Ou: ssh -i ${NEW_PRIVATE_KEY} ${USER}@${BASTION_IP}"
    log "   Tunnel RDS: ssh -L 5432:rds-endpoint:5432 bastion-${NEW_KEY_NAME} -N"
    echo
    warn "# Dica: A chave de acesso original (${EXISTING_KEY}) ainda é necessária para este script."
    warn "       A nova chave (${NEW_PRIVATE_KEY}) agora tem acesso independente."
    log "=========================================="
}


# Executar função principal
main "$@"
