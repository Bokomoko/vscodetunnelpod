#!/bin/bash
set -e

# Definir valores padrão se não estiverem definidos
TUNNEL_NAME=${TUNNEL_NAME:-"dev-tunnel-$(whoami)-$(hostname)"}
USERNAME=${USERNAME:-"vscode"}
TZ=${TZ:-"America/Recife"}

# Configurar timezone se especificada
if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
    echo "Configurando timezone para: $TZ"
    rm -f /etc/localtime /etc/timezone
    cp "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
    export TZ
else
    echo "Timezone não especificada ou inválida, usando padrão do sistema"
fi

echo "=== VS Code Tunnel Container ==="
echo "Usuário: $USERNAME (UID: $USER_UID, GID: $USER_GID)"
echo "Timezone: $TZ"
echo "Tunnel Name: $TUNNEL_NAME"
echo "Workspace: /workspace"
echo "================================"

# Verificar se o diretório workspace existe e tem conteúdo
if [ ! -d "/workspace" ] || [ -z "$(ls -A /workspace)" ]; then
    echo "⚠️  Aviso: Diretório /workspace está vazio ou não existe"
    echo "   Certifique-se de montar o volume ~/src:/workspace"
fi

# Instalar extensões se for a primeira execução
if [ ! -f "/home/$USERNAME/.vscode-server/.extensions-installed" ]; then
    echo "🔧 Primeira execução - instalando extensões..."
    /usr/local/bin/install-extensions.sh || true
    touch "/home/$USERNAME/.vscode-server/.extensions-installed"
fi

# Definir diretório de trabalho
cd /workspace

# Mostrar informações de debug
echo "📁 Conteúdo do workspace:"
ls -la /workspace | head -10

echo "🚀 Iniciando VS Code Tunnel..."
echo "   Nome: $TUNNEL_NAME"
echo "   Acesso: https://vscode.dev/tunnel ou aguarde interface local"

# Executar diretamente (já estamos como usuário correto)
exec /usr/local/bin/code tunnel --accept-server-license-terms --name "$TUNNEL_NAME"
