#!/bin/bash
set -e

echo "=== VS Code Tunnel Container ==="
echo "Usuário: $USERNAME (UID: $USER_UID, GID: $USER_GID)"
echo "Timezone: $TZ"
echo "Tunnel Name: $TUNNEL_NAME"
echo "Serve Mode: $VSCODE_SERVE_MODE"
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
echo "   Modo: $VSCODE_SERVE_MODE"
echo "   Nome: $TUNNEL_NAME"
echo "   Porta: 8000"

# Executar diretamente (já estamos como usuário correto)
exec /usr/local/bin/code tunnel --accept-server-license-terms --name "$TUNNEL_NAME" --$VSCODE_SERVE_MODE --host 0.0.0.0 --port 8000
