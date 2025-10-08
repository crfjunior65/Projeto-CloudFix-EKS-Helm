#!/bin/bash
# aws-profile-manager.sh

# Diretório para armazenar as configurações
CONFIG_DIR="$HOME/.aws/"
mkdir -p $CONFIG_DIR

# Função para listar perfis
list_profiles() {
    echo "Perfis AWS disponíveis:"
    grep -o '\[[^]]*\]' $CONFIG_DIR/credentials 2>/dev/null | sed 's/\.sh//g'
    echo ""
    echo "Perfil atual: $AWS_PROFILE"
}

# Função para criar/editar um perfil
create_profile() {
    local profile_name=$1
    if [ -z "$profile_name" ]; then
        echo "Usage: source aws-profile-manager.sh create <profile_name>"
        return 1
    fi

    echo "Configurando perfil: $profile_name"
    read -p "AWS Access Key ID: " access_key
    read -s -p "AWS Secret Access Key: " secret_key
    echo ""
    read -p "AWS Region [us-east-1]: " region
    read -p "Output format [json]: " output_format

    region=${region:-us-east-1}
    output_format=${output_format:-json}

    cat >> "$CONFIG_DIR/credentials" << EOF
[${profile_name}]
AWS_ACCESS_KEY_ID="$access_key"
AWS_SECRET_ACCESS_KEY="$secret_key"
AWS_REGION="$region"
EOF

    echo "Perfil $profile_name criado com sucesso!"
}

# Função para usar um perfil
use_profile() {
    local profile_name=$1
    if [ -z "$profile_name" ]; then
        echo "Usage: source aws-profile-manager.sh use <profile_name>"
        return 1
    fi

    if [ ! -f "$CONFIG_DIR/credentials" ]; then
        echo "Perfil $profile_name não encontrado!"
        return 1
    fi

    # Limpa variáveis atuais
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_DEFAULT_REGION
    unset AWS_REGION
    unset AWS_DEFAULT_OUTPUT
    unset AWS_PROFILE

    # Carrega o perfil
    #source "$CONFIG_DIR/${profile_name}.sh"
    export AWS_PROFILE="$profile_name"
    echo "Perfil $profile_name ativado!"

    # Testa a conexão
    echo "Testando conexão..."
    aws sts get-caller-identity --query "Arn" --output text
    echo $AWS_PROFILE
}

# Função para deletar um perfil
delete_profile() {
    local profile_name=$1
    if [ -z "$profile_name" ]; then
        echo "Usage: source aws-profile-manager.sh delete <profile_name>"
        return 1
    fi

    if [ -f "$CONFIG_DIR/${profile_name}.sh" ]; then
        rm "$CONFIG_DIR/${profile_name}.sh"
        echo "Perfil $profile_name removido!"
    else
        echo "Perfil $profile_name não encontrado!"
    fi
}

# Função para mostrar o perfil atual
show_current() {
    echo "Credenciais atuais:"
    echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:10}..."
    echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"
    echo "AWS_PROFILE: $AWS_PROFILE"

    if command -v aws &> /dev/null; then
        echo ""
        echo "Testando identidade AWS:"
        aws sts get-caller-identity --query "Arn" --output text 2>/dev/null || echo "Erro ao conectar"
    fi
}

# Menu principal
case "$1" in
    "list")
        list_profiles
        ;;
    "create")
        create_profile "$2"
        ;;
    "use")
        use_profile "$2"
        ;;
    "delete")
        delete_profile "$2"
        ;;
    "show")
        show_current
        ;;
    *)
        echo "AWS Profile Manager"
        echo "Commands:"
        echo "  list                          - Lista todos os perfis"
        echo "  create <profile_name>         - Cria um novo perfil"
        echo "  use <profile_name>            - Usa um perfil específico"
        echo "  delete <profile_name>         - Remove um perfil"
        echo "  show                          - Mostra o perfil atual"
        ;;
esac
