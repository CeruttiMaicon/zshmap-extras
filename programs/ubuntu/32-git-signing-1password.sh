#!/bin/sh

# Configura commits/tags assinados com chave SSH do 1Password
#
# Requisitos:
#   - 1Password (app desktop) instalado, com "SSH Agent" ativado
#     (Settings > Developer > Use the SSH Agent) e desbloqueado
#
# Variáveis opcionais:
#   GIT_SIGNING_KEY  chave pública a usar (ex.: "ssh-ed25519 AAAA...")
#   GIT_USER_NAME    nome do git (se user.name ainda não estiver definido)
#   GIT_USER_EMAIL   e-mail do git (se user.email ainda não estiver definido)

set -e

# O ZshMap costuma correr com sudo: volta a correr como o utilizador real,
# senão a configuração iria para o /root
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    exec sudo -u "$SUDO_USER" -H \
        GIT_SIGNING_KEY="$GIT_SIGNING_KEY" \
        GIT_USER_NAME="$GIT_USER_NAME" \
        GIT_USER_EMAIL="$GIT_USER_EMAIL" \
        sh "$0" "$@"
fi

DEFAULT_NAME="Maicon Cerutti"
DEFAULT_EMAIL="dev.cerutti.maicon@gmail.com"
OP_SSH_SIGN="/opt/1Password/op-ssh-sign"
OP_AGENT_SOCK="$HOME/.1password/agent.sock"
SSH_CONFIG="$HOME/.ssh/config"
ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"

# Pergunta com valor por omissão (usa o default se não houver terminal)
ask() {
    if [ -t 0 ]; then
        printf '%s [%s]: ' "$1" "$2" >&2
        read -r answer
        echo "${answer:-$2}"
    else
        echo "$2"
    fi
}

echo "🔧 Configurando assinatura de commits com 1Password..."
echo ""

if ! command -v git >/dev/null 2>&1; then
    echo "❌ git não está instalado."
    exit 1
fi

if [ ! -x "$OP_SSH_SIGN" ]; then
    echo "❌ $OP_SSH_SIGN não encontrado."
    echo "   Instala o app desktop do 1Password (o 1password-cli sozinho não traz o op-ssh-sign)."
    exit 1
fi

# ~/.ssh/config: usar o agente do 1Password
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -f "$SSH_CONFIG" ] && grep -q "1password/agent.sock" "$SSH_CONFIG"; then
    echo "ℹ️  ~/.ssh/config já usa o agente do 1Password."
else
    printf 'Host *\n\tIdentityAgent ~/.1password/agent.sock\n' >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    echo "✅ IdentityAgent do 1Password adicionado ao ~/.ssh/config"
fi

# Nome e e-mail
name="$(git config --global user.name || true)"
email="$(git config --global user.email || true)"
if [ -z "$name" ]; then
    name="${GIT_USER_NAME:-$(ask "Nome para o git" "$DEFAULT_NAME")}"
    git config --global user.name "$name"
fi
if [ -z "$email" ]; then
    email="${GIT_USER_EMAIL:-$(ask "E-mail para o git" "$DEFAULT_EMAIL")}"
    git config --global user.email "$email"
fi
echo "ℹ️  Autor: $name <$email>"

# Chave de assinatura
key="$GIT_SIGNING_KEY"
if [ -z "$key" ]; then
    if [ ! -S "$OP_AGENT_SOCK" ]; then
        echo "❌ Agente SSH do 1Password não encontrado em $OP_AGENT_SOCK."
        echo "   Abre o 1Password, ativa Settings > Developer > Use the SSH Agent e desbloqueia o cofre."
        exit 1
    fi

    keys="$(SSH_AUTH_SOCK="$OP_AGENT_SOCK" ssh-add -L 2>/dev/null || true)"
    if [ -z "$keys" ] || ! echo "$keys" | grep -q '^ssh-'; then
        echo "❌ Nenhuma chave no agente do 1Password (está desbloqueado?)."
        exit 1
    fi

    count="$(echo "$keys" | wc -l)"
    if [ "$count" -eq 1 ]; then
        key="$(echo "$keys" | cut -d' ' -f1-2)"
    else
        echo ""
        echo "Chaves disponíveis no 1Password:"
        echo "$keys" | awk '{ printf "  %d) %s ...%s  %s\n", NR, $1, substr($2, length($2) - 7), substr($0, index($0, $3)) }'
        # Por omissão, a primeira ed25519
        default="$(echo "$keys" | awk '$1 == "ssh-ed25519" { print NR; exit }')"
        choice="$(ask "Qual chave usar para assinar" "${default:-1}")"
        key="$(echo "$keys" | sed -n "${choice}p" | cut -d' ' -f1-2)"
        if [ -z "$key" ]; then
            echo "❌ Opção inválida: $choice"
            exit 1
        fi
    fi
fi
echo "ℹ️  Chave: $(echo "$key" | cut -c1-30)..."

# Configuração do git
git config --global gpg.format ssh
git config --global user.signingkey "$key"
git config --global gpg.ssh.program "$OP_SSH_SIGN"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# allowed_signers (para git log --show-signature verificar localmente)
touch "$ALLOWED_SIGNERS"
if grep -qF "$email $key" "$ALLOWED_SIGNERS"; then
    echo "ℹ️  Chave já está em ~/.ssh/allowed_signers"
else
    echo "$email $key" >> "$ALLOWED_SIGNERS"
    echo "✅ Chave adicionada a ~/.ssh/allowed_signers"
fi
git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"
echo "✅ Assinatura configurada no ~/.gitconfig"

# Teste: commit vazio num repositório temporário
echo ""
echo "🧪 Testando assinatura (o 1Password pode pedir autorização)..."
tmp="$(mktemp -d)"
if git -C "$tmp" init -q && git -C "$tmp" commit -q --allow-empty -m "teste assinatura" \
    && git -C "$tmp" verify-commit HEAD >/dev/null 2>&1; then
    echo "✅ Commit assinado e verificado com sucesso!"
    result=0
else
    echo "❌ Falha ao assinar. Confere se o 1Password está aberto e desbloqueado."
    result=1
fi
rm -rf "$tmp"

echo ""
echo "📌 Não te esqueças: a chave tem de estar no GitHub como \"Signing Key\""
echo "   e o e-mail $email tem de estar verificado na conta."
echo ""
echo "✨ Configuração concluída!"

exit $result
