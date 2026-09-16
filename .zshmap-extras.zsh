# .zshmap-extras.zsh — shell pessoal carregado pelo .zprofile-auto (ZshMap)
#
# Configuração: em ~/.zshmap.yml usa shell.extras_source (lista) com o caminho deste ficheiro.
# Não dupliques aqui o que já está nos zshmap.yml dos projetos (Docker, testes, etc.).
#
# Exemplos do que costuma ir aqui: clone_repo, aliases multi-repo, multiplier-*, update, NVM.

# Coloca abaixo aliases e funções pessoais.

# Define a variável com valor padrão 32 (pode ser sobrescrita externamente)
# Define se o truncamento do nome da branch será feito e qual o tamanho para o terminal do Powerlevel10k
MY_BRANCH_SHORTEN_LENGTH=${MY_BRANCH_SHORTEN_LENGTH:-0}

if [[ -f ~/.p10k.zsh ]]; then
  if [[ "$MY_BRANCH_SHORTEN_LENGTH" -eq 0 ]]; then
    # Se for 0, comenta a linha que contém o truncamento e adiciona 6 espaços no início
    sed -i.bak -E '/branch\[13,-13\]="…"/ {
      s/^[[:space:]]*//;
      s/^/      #/
    }' ~/.p10k.zsh
  else
    # Se for diferente de 0, remove o comentário, força a indentação com 6 espaços
    # e substitui o número pelo valor definido em MY_BRANCH_SHORTEN_LENGTH
    sed -i.bak -E '/branch\[13,-13\]="…"/ {
      s/^[[:space:]]*#?[[:space:]]*//;
      s/^/      /;
      s/(\(\(\s*\$#branch\s*>\s*)[0-9]+(\s*\)\)\s*&&\s*branch\[13,-13\]="…")/\1'"${MY_BRANCH_SHORTEN_LENGTH}"'\2/
    }' ~/.p10k.zsh
  fi
fi

if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
  export LIBGL_ALWAYS_SOFTWARE=1
fi

export sufixo="_masked"

alias ohmyzsh="code ~/.oh-my-zsh"
alias zshprofile="code ~/Projects/zsh-map/.zprofile"
alias zshconfig="code ~/.zshrc"
alias conf-neovim="code ~/.config/nvim/init.vim"
alias conf-vim="code ~/.vimrc"

alias zsh-map-exec="cd ~/Projects/zsh-map/ && ./zsh-map.sh"
alias zsh-map-update="zsh-map-update"

# Alias genérico para logs do Laravel
alias logs="laravel-logs"

# Alias atualizados para usar a função clone_repo
alias mia="clone_repo ~/Projects/mia git@github.com:igorguima/bedrock-node-app.git mia && cd ~/Projects/mia"
alias srp="clone_repo ~/Projects/srp git@github.com:multiplierx/srp.git srp && cd ~/Projects/srp"
alias srp-deploy="clone_repo ~/Projects/srp-deploy git@github.com:multiplierx/srp.git srp-deploy && cd ~/Projects/srp-deploy"
alias srp-docs="clone_repo ~/Projects/srp-docs git@github.com:multiplierx/srp-docs.git && cd ~/Projects/srp-docs"
alias front="clone_repo ~/Projects/front git@github.com:multiplierx/front.git && cd ~/Projects/front"
alias front-deploy="clone_repo ~/Projects/front-deploy git@github.com:multiplierx/front.git front-deploy && cd ~/Projects/front-deploy"
alias email="clone_repo ~/Projects/email git@github.com:multiplierx/email.git && cd ~/Projects/email"
alias zsh-map="clone_repo ~/Projects/zsh-map git@github.com:CeruttiMaicon/zsh-map.git && cd ~/Projects/zsh-map"
alias zshmap-extras="clone_repo ~/Projects/zshmap-extras git@github.com:CeruttiMaicon/zshmap-extras.git && cd ~/Projects/zshmap-extras"
alias VolleyTrackBack="clone_repo ~/Projects/VoleiClub git@github.com:Zoren-Software/VolleyTrack-Back.git && cd ~/Projects/VoleiClub"
alias VolleyTrackFront="clone_repo ~/Projects/VoleiClub-Front git@github.com:Zoren-Software/VolleyTrack-Front.git && cd ~/Projects/VoleiClub-Front"
alias VolleyTrackDocs="clone_repo ~/Projects/Zoren-Software.github.io git@github.com:Zoren-Software/Zoren-Software.github.io.git && cd ~/Projects/Zoren-Software.github.io"
alias LandingPageBack="clone_repo ~/Projects/LandingPage-BackEnd-VoleiClub git@github.com:Zoren-Software/LandingPage-BackEnd-VoleiClub.git && cd ~/Projects/LandingPage-BackEnd-VoleiClub"
alias LandingPageFront="clone_repo ~/Projects/LandingPage-FrontEnd-VoleiClub git@github.com:Zoren-Software/LandingPage-FrontEnd-VoleiClub.git && cd ~/Projects/LandingPage-FrontEnd-VoleiClub"
alias MarketingHubPlugin="clone_repo ~/Projects/zap-sender-plugin git@github.com:Zoren-Software/zap-sender-plugin.git && cd ~/Projects/zap-sender-plugin"
alias MarketingHubBack="clone_repo ~/Projects/zap-sender-back git@github.com:Zoren-Software/zap-sender-back.git && cd ~/Projects/zap-sender-back"

# Workspaces (~/Workspaces/*.code-workspace)
# Os .code-workspace ficam versionados em zshmap-extras/workspaces/ (paths
# relativos, ex.: "../Projects/srp") e são sincronizados para ~/Workspaces
# sempre que um atalho de workspace é chamado (recria a pasta/arquivo mesmo
# que ~/Workspaces tenha sido apagada depois do terminal aberto).
# Gera-se uma função por editor instalado para cada workspace encontrado,
# ex.: ~/Workspaces/srp.code-workspace -> função code-srp e, se o Cursor
# estiver instalado, também cursor-srp.
function sincronizar_workspaces() {
    local workspaces_repo_dir="$HOME/Projects/zshmap-extras/workspaces"
    local workspaces_dir="$HOME/Workspaces"

    if [[ ! -d "$workspaces_repo_dir" ]]; then
        return
    fi

    mkdir -p "$workspaces_dir"

    if command -v rsync &> /dev/null; then
        rsync -a "$workspaces_repo_dir"/*.code-workspace "$workspaces_dir/" 2>/dev/null
    else
        cp -f "$workspaces_repo_dir"/*.code-workspace(N) "$workspaces_dir/" 2>/dev/null
    fi
}

# Clona as pastas de projeto referenciadas num .code-workspace que ainda não
# existam em ~/Projects. O mapa pasta->URL git é extraído dos próprios
# aliases "clone_repo ~/Projects/<pasta> <url>" já definidos neste ficheiro
# (linhas 51-66), então não há URLs duplicadas: um clone_repo novo já entra
# automaticamente para uso em workspaces.
function clonar_pastas_workspace() {
    local workspace_file="$1"
    local extras_file="$HOME/Projects/zshmap-extras/.zshmap-extras.zsh"
    local pasta dir url linha

    if [[ ! -f "$workspace_file" || ! -f "$extras_file" ]]; then
        return
    fi

    for pasta in $(command grep -oE '"path": *"\.\./Projects/[^"]+"' "$workspace_file" | sed -E 's#.*Projects/([^"]+)"#\1#' | sort -u); do
        dir="$HOME/Projects/$pasta"

        if [[ -d "$dir" ]]; then
            echo -e "\033[0;32m✅ Pasta $dir já existe.\033[0m"
            continue
        fi

        linha="$(command grep -m1 "clone_repo ~/Projects/${pasta} " "$extras_file")"
        url="$(echo "$linha" | sed -E 's#.*clone_repo ~/Projects/'"$pasta"' +([^ ]+).*#\1#')"

        if [[ -n "$url" ]]; then
            echo -e "\033[0;36m📦 Pasta $dir não encontrada. Clonando $url...\033[0m"
            git clone "$url" "$dir"
        else
            echo -e "\033[0;33m⚠️  Nenhum clone_repo mapeado para '$pasta'. Pulei o clone automático.\033[0m"
        fi
    done
}

function gerar_aliases_workspaces() {
    local workspaces_repo_dir="$HOME/Projects/zshmap-extras/workspaces"
    local workspaces_dir="$HOME/Workspaces"
    local workspace_file nome editor

    if [[ ! -d "$workspaces_repo_dir" ]]; then
        return
    fi

    for workspace_file in "$workspaces_repo_dir"/*.code-workspace(N); do
        nome="$(basename "$workspace_file" .code-workspace)"

        for editor in code cursor; do
            if command -v "$editor" &> /dev/null; then
                eval "function ${editor}-${nome}() {
                    sincronizar_workspaces
                    clonar_pastas_workspace \"${workspaces_dir}/${nome}.code-workspace\"
                    ${editor} \"${workspaces_dir}/${nome}.code-workspace\"
                }"
            fi
        done
    done
}

gerar_aliases_workspaces

# Atalhos
alias cl="clear"

# Obs
alias obs="QT_QPA_PLATFORM=xcb obs"
function verificar_apache2() {
    if ! command -v apache2 &> /dev/null; then
        # echo -e "\033[0;33mO Apache2 não está instalado. ❌❌❌ Pulando parada do serviço.\033[0m"
        true
    else
        sudo service apache2 stop
    fi
}

# Adicione esta função de notificação ao seu script para reutilizar
function notificar() {
    titulo="$1"
    mensagem="$2"
    icone="${3:-info}"

    # Verifica se o notify-send está instalado
    if ! command -v notify-send &> /dev/null; then
        echo -e "\033[31mO pacote notify-send não está instalado. Instalando...\033[0m"
        sudo apt update && sudo apt install -y libnotify-bin
    fi

    # criar variavel com o caminho da imagem
    # Imagens em ~/Projects/zsh-map/images/ (ajusta se o clone estiver outro sítio)
    icone_path="$HOME/Projects/zsh-map/images/$icone.png";

    notify-send -i "$icone_path" "$titulo" "$mensagem" --app-name="ZshMap" --urgency=normal --expire-time=500
}

trap clean_up SIGINT

function clean_up() {
    echo "Processo cancelado pelo usuário. Saindo..."
    # Adicione aqui qualquer comando de limpeza que precise ser executado antes de sair
    exit 1
}

function download() {
    link="$1"
    nome_arquivo="${2:-$(basename "$link")}"

    if [[ -z "$link" ]]; then
        echo -e "\033[0;33mUso: download <url> [nome_do_arquivo]\033[0m"
        return 2
    fi

    echo -e "\033[0;34mIniciando download de:\033[0m $link \n"
    echo -e "\033[0;34mSalvando como:\033[0m $nome_arquivo \n"

    wget -c --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 --tries=0 "$link" -O "$nome_arquivo" || {
        echo -e "\033[0;31mErro: Falha ao baixar o arquivo. Verifique o link e tente novamente.\033[0m"
        return 1
    }

    echo -e "\033[0;32mDownload concluído com sucesso:\033[0m $nome_arquivo"
}

function verificar_container() {
    local container_name="$1"
    local start_function="$2"

    # Verifica se o nome do container foi passado
    if [ -z "$container_name" ] || [ -z "$start_function" ]; then
        echo -e "\033[0;31mErro: Parâmetros ausentes! É necessário informar o nome do container e a função de inicialização.\033[0m"
        echo "Uso: verificar_container nome_do_container função_de_start"
        return 1
    fi

    container_status=$(docker inspect --format="{{.State.Running}}" "$container_name" 2>/dev/null)

    if [ "$container_status" != "true" ]; then
        echo "Container '$container_name' não está rodando. 🚨 Iniciando... 🚀 \n"
        eval "$start_function"
    else
        echo "Container '$container_name' já está rodando. ✅"
    fi

    # Mensagem amigável aguardando o container iniciar
    echo -e "\n⏳ Aguardando container '$container_name' iniciar em 5 segundos... Pressione Ctrl+C para cancelar.\n"
    for i in {5..1}
    do
        echo "⏳ Aguardando... $i"
        sleep 1
        if [ "$i" -eq 1 ]; then
            echo "⏳ Processo iniciado! 🚀 \n"
        fi
    done
}


function verificar_composer_update() {
    local container="$1"
    local projeto_nome="$2"
    local projeto_dir="$3"  # Caminho completo do projeto no host
    local pasta_multiplier="${4:-.worker-boss}" # Pasta padrão do Projeto

    local projeto_hash_dir="$HOME/.multiplier/$pasta_multiplier/composer-lock/$projeto_nome"
    local cache_hash_file="$projeto_hash_dir/composer.lock.hash"

    echo -e "\n"
    echo -e "📦 Verificando mudanças no composer.lock para o projeto '$projeto_nome'... \n"
    echo -e "📁 Usando cache hash em: $cache_hash_file \n"

    # Garante que o diretório do projeto exista
    if [ ! -d "$projeto_hash_dir" ]; then
        mkdir -p "$projeto_hash_dir"
        echo -e "📁 Diretório '$projeto_hash_dir' criado para armazenar hash. ✅ \n"
    fi

    # Garante que o diretório do projeto no host existe (sanity check)
    if [ ! -d "$projeto_dir" ]; then
        echo -e "\033[0;31m❌ Diretório do projeto '$projeto_dir' não encontrado.\033[0m"
        return 1
    fi

    # Obtém hash atual do composer.lock dentro do container
    local current_hash=$(docker exec "$container" sha1sum composer.lock | awk '{ print $1 }')

    # Se não houver hash salvo, cria e instala dependências
    if [ ! -f "$cache_hash_file" ]; then
        echo "$current_hash" > "$cache_hash_file"
        echo -e "📦 Sem hash anterior. Rodando composer install...\n"
        docker exec -it "$container" composer install
        return
    fi

    # Lê hash salvo e compara
    local last_hash=$(cat "$cache_hash_file")

    if [ "$current_hash" != "$last_hash" ]; then
        echo -e "📦 Alteração detectada no composer.lock. Instalando dependências...\n"
        docker exec -it "$container" composer install
        echo "$current_hash" > "$cache_hash_file"
    else
        echo -e "📦 Nenhuma alteração detectada. composer install ignorado. ✅\n"
    fi
}

function git-rename-branch() {

    # criar validaçao para verificar se existem 2 parametros
    # criar validaçao para verificar se o primeiro parametro é diferente do segundo
    if [ "$#" -ne 2 ]; then
        #imprimir erro em vermelho
        echo -e "\033[0;31mErro!!! ❌❌❌\033[0m";
        echo -e "\033[0;31mÉ necessário informar dois parâmetros o nome antigo e o novo nome da branch. \033[0m \n";
        echo "Este comando renomeia uma branch local e remota."
        echo "Uso: git-rename-branch nome_antigo nome_novo"
        echo "Exemplo: git-rename-branch master main"
        return
    fi

    git branch -m $1 $2
    git push origin :$1 $2

    echo -e "\033[0;32mBranch renomeada com sucesso!!! ✅✅✅\033[0m";
}

# Git
alias gfetch="git fetch --all --prune && git tag -d \$(git tag) && git fetch --tags && for branch in \$(git branch -vv | grep ': gone]' | awk '{print \$1}'); do git branch -D \$branch; done && git pull"
alias branch="git branch --show-current"
alias gps="git push --set-upstream origin \$(git branch --show-current)"


# Informações do computador
alias ubuntu="verificar_neofetch"
alias popos="verificar_neofetch"

# Eza
alias eza="verificar_eza"
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -l"
alias grep="grep --color"

function verificar_neofetch() {
  if command -v neofetch &> /dev/null; then
    neofetch
  else
    echo "O pacote neofetch não está instalado ❌❌❌. Instalando..."
    sudo apt update && sudo apt install neofetch
    echo -e "\033[0;32mInstalação concluída ✅✅✅. Executando neofetch...\033[0m";
    neofetch
  fi
}

function verificar_jq() {
    if command -v jq &> /dev/null; then
        command jq "$@"
    else
        echo "O pacote jq não está instalado ❌❌❌. Instalando..."
        sudo apt update && sudo apt install jq
        echo -e "\033[0;32mInstalação concluída ✅✅✅. Executando jq...\033[0m";
        command jq "$@"
    fi
}

function verificar_eza() {
    if command -v eza &> /dev/null; then
        command eza "$@"
    else
        echo "O pacote eza não está instalado ❌❌❌. Instalando..."
        sudo apt update &&
        sudo apt install -y gpg &&
        sudo mkdir -p /etc/apt/keyrings &&
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg &&
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list &&
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list &&
        sudo apt update &&
        sudo apt install -y eza &&
        echo -e "\033[0;32mInstalação concluída ✅✅✅. Executando eza...\033[0m";
        command eza "$@"
    fi
}

# Atualizar snaps
function atualizar-snap() {
    echo "Atualizando snaps..."
    if command -v snap &> /dev/null; then
        sudo snap refresh
    else
        echo "\033[31mO pacote do Snap não está instalado. ❌❌❌\033[0m"
    fi
}

# Verifica se um programa está instalado e instala se necessário
function is-program-installed() {
  command -v "$1" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "\033[0;32m$1 está instalado. E irá continuar com a atualização do sistema... ✅ \033[0m \n"
    update-system
  else
    echo "$1 não está instalado."
    echo "instalando..."
    echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
    wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
    sudo apt update && sudo apt install nala
    echo -e "\033[0;32mInstalação concluída ✅✅✅ \033[0m \n"
    update-system
  fi
}

# Atualiza o sistema usando o nala
function update-system() {
  sudo nala update
  sudo nala upgrade -y
  sudo nala autoremove -y
  sudo nala clean
  atualizar-snap
}

# Função mestre para atualizar o sistema
function update() {

  is-program-installed "nala"

  update-system

  zsh-map-update
}

# Função para atualizar o clone do zsh-map (git pull)
function zsh-map-update() {
  echo -e "\033[0;36m🧪 Atualizando o repositório zsh-map...\033[0m"
  
  # Salva o diretório atual
  local current_dir=$(pwd)
  
  # Vai para o diretório do zsh-map
  zsh-map
  
  # Verifica se é um repositório git
  if [ ! -d ".git" ]; then
    echo -e "\033[0;31m❌ Erro: Este diretório não é um repositório git!\033[0m"
    cd "$current_dir"
    return 1
  fi
  
  # Faz o pull das alterações
  echo -e "\033[0;33m⬇️  Baixando alterações do repositório...\033[0m"
  local pull_output=$(git pull 2>&1)
  local pull_exit_code=$?
  
  # Verifica se houve alterações
  if [ $pull_exit_code -eq 0 ]; then
    # Verifica se o pull realmente baixou alterações
    if [[ "$pull_output" == *"Already up to date"* ]]; then
      echo -e "\033[0;36mℹ️  Nenhuma alteração encontrada. O projeto já está atualizado.\033[0m"
    else
      echo -e "\033[0;32m✅ Projeto atualizado com sucesso!\033[0m"
      echo -e "\033[0;34m🔄 É necessário reiniciar o terminal para continuar!\033[0m"
      echo -e "\033[0;34m💡 Execute: source ~/.zprofile\033[0m"
    fi
  else
    echo -e "\033[0;31m❌ Erro ao fazer pull: $pull_output\033[0m"
  fi
  
  # Retorna ao diretório original
  cd "$current_dir"
}

# ls após cd só quando você digita "cd" no prompt (não em scripts/funções)
if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  typeset -g _ZSHMAP_CD_LS_PENDING=0

  _zshmap_preexec_cd_ls() {
    if [[ "$1" =~ '^[[:space:]]*cd([[:space:]]|;|&&|$)' ]]; then
      _ZSHMAP_CD_LS_PENDING=1
    else
      _ZSHMAP_CD_LS_PENDING=0
    fi
  }

  _zshmap_chpwd_ls() {
    if (( _ZSHMAP_CD_LS_PENDING )); then
      _ZSHMAP_CD_LS_PENDING=0
      ls
    fi
  }

  add-zsh-hook preexec _zshmap_preexec_cd_ls
  add-zsh-hook chpwd _zshmap_chpwd_ls
fi

function verificar_dependencia() {
    local comando="$1"

    if command -v "$comando" &> /dev/null; then
        echo -e "\033[0;36m🔎 $comando já está instalado.\033[0m\n"
    else
        echo -e "\033[0;33m🔧 Instalando $comando...\033[0m\n"
        sudo apt update && sudo apt install -y "$comando"
        echo -e "\033[0;32m✅ $comando instalado com sucesso!\033[0m\n"
    fi
}

function verificar_pacote() {
    local base="$1"

    if dpkg -l | grep -E "^ii\s+$base" &>/dev/null || dpkg -l | grep -E "^ii\s+${base}[a-zA-Z0-9:-]*" &>/dev/null; then
        echo -e "\033[0;36m🔎 Pacote $base já está instalado.\033[0m\n"
    else
        echo -e "\033[0;33m🔧 Instalando pacote $base...\033[0m\n"
        sudo apt update && sudo apt install -y "$base" && \
        echo -e "\033[0;32m✅ Pacote $base instalado com sucesso!\033[0m\n" || \
        echo -e "\033[0;31m❌ Falha ao instalar o pacote $base\033[0m\n"
    fi
}

# Vim
alias v="nvim"

# Laravel Sail
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

# PNPM
alias p="pnpm"

# Função para verificar e clonar repositório se necessário
function clone_repo() {
    local dir=$1
    local repo_url=$2
    local repo_name=${3:-$(basename $repo_url .git)}
    
    # Expandir ~ no caminho
    dir="${dir/#\~/$HOME}"

    if [ ! -d "$dir" ]; then
        echo -e "\nDiretório $dir não encontrado. Clonando repositório... 🌎🌎🌎 \n"
        git clone "$repo_url" "$dir"
    else
        echo -e "\nDiretório $dir já existe. Pulando clonagem... ✅✅✅ \n"
    fi
}

# Starship (RPROMPT: relógio à direita na 2ª linha sem mover o cursor)
export ZLE_RPROMPT_INDENT=0

eval "$(starship init zsh)"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Variáveis de ambiente do Go
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Configuração assinatura commits 1Password
echo 'export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"' >> ~/.zshrc