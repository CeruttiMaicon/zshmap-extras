#!/bin/sh

# Instalação Claude Code CLI

set -e

# O instalador instala em ~/.local/bin: com sudo iria para o /root,
# então volta a correr como o utilizador real
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    exec sudo -u "$SUDO_USER" -H sh "$0" "$@"
fi

curl -fsSL https://claude.ai/install.sh | bash
