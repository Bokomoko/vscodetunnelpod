#!/bin/bash
set -e

EXTENSIONS_FILE="/home/${USERNAME}/.config/extensions.txt"

if [ -f "$EXTENSIONS_FILE" ]; then
    echo "Instalando extensões do VS Code..."
    while IFS= read -r extension; do
        # Ignorar linhas vazias e comentários
        if [[ -n "$extension" && ! "$extension" =~ ^[[:space:]]*# ]]; then
            echo "Instalando: $extension"
            /usr/local/bin/code --install-extension "$extension" --force || echo "Falha ao instalar: $extension"
        fi
    done < "$EXTENSIONS_FILE"
    echo "Instalação de extensões concluída!"
else
    echo "Arquivo de extensões não encontrado: $EXTENSIONS_FILE"
fi
