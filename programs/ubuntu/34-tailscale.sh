#!/bin/sh

# Instalação do Tailscale e do OpenSSH.
# Corre com sh (o menu do ZshMap usa sudo -S sh e descarta o stderr).

set -eu

if [ "$(id -u)" -eq 0 ]; then
    run() {
        env DEBIAN_FRONTEND=noninteractive "$@"
    }
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Erro: este script precisa de root ou sudo."
        exit 1
    fi
    run() {
        sudo env DEBIAN_FRONTEND=noninteractive "$@"
    }
fi

if [ ! -r /etc/os-release ]; then
    echo "Erro: /etc/os-release não encontrado."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

os_id="${ID:-}"
os_like="${ID_LIKE:-}"
supported=0
case "$os_id" in
    ubuntu|debian)
        supported=1
        ;;
esac
case " $os_like " in
    *" ubuntu "*|*" debian "*)
        supported=1
        ;;
esac
if [ "$supported" -ne 1 ]; then
    echo "Erro: distribuição não suportada (${os_id:-desconhecida}). Este script é para Ubuntu ou Debian."
    exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
    echo "Erro: apt não está disponível."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Erro: curl não está disponível."
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Erro: systemctl não está disponível."
    exit 1
fi

echo "A atualizar os índices de pacotes..."
run apt update

echo "A instalar o OpenSSH..."
run apt install -y openssh-client openssh-server iproute2
run systemctl enable --now ssh

if ! run systemctl is-active --quiet ssh; then
    echo "Erro: o serviço SSH não está ativo."
    exit 1
fi

if ! command -v ss >/dev/null 2>&1; then
    echo "Erro: o comando ss não está disponível."
    exit 1
fi

if ! ss -lnt | grep -q ':22 '; then
    echo "Erro: nada está a escutar na porta 22."
    exit 1
fi

echo "SSH está ativo na porta 22."

if ! command -v tailscale >/dev/null 2>&1; then
    echo "A instalar o Tailscale..."
    installer=$(mktemp)
    trap 'rm -f "$installer"' EXIT
    if ! curl -fsSL https://tailscale.com/install.sh -o "$installer"; then
        echo "Erro: não foi possível obter o instalador do Tailscale."
        exit 1
    fi
    run sh "$installer"
    rm -f "$installer"
    trap - EXIT
else
    echo "Tailscale já está instalado."
fi

if ! command -v tailscale >/dev/null 2>&1; then
    echo "Erro: o Tailscale não ficou disponível no PATH."
    exit 1
fi

run systemctl enable --now tailscaled

status_json=$(run tailscale status --json 2>/dev/null || true)
backend_state=$(printf '%s\n' "$status_json" | sed -n 's/.*"BackendState"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)

if [ "$backend_state" = "Running" ]; then
    echo "Tailscale já está conectado."
else
    echo "A abrir o login do Tailscale. Usa o link abaixo no browser."
    run tailscale up
fi

echo "IPv4 Tailscale:"
run tailscale ip -4

if ! run systemctl is-active --quiet ssh; then
    echo "Erro: o serviço SSH não está ativo."
    exit 1
fi

echo "SSH está ativo. A outra máquina da mesma conta entra com: ssh <utilizador>@<ip-tailscale>"
