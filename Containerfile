# VS Code Tunnel Container
# Baseado em Alpine Linux para menor tamanho
FROM alpine:3.19

# Metadata
LABEL maintainer="bokomoko" \
      description="VS Code Tunnel Container" \
      version="1.0"

# Variáveis de ambiente
ENV USER_UID=1000 \
    USER_GID=1000 \
    USERNAME=vscode \
    TUNNEL_NAME=dev-tunnel \
    VSCODE_SERVE_MODE=serve-web \
    TZ=America/Recife

# Instalar dependências do sistema
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    openssh-client \
    ca-certificates \
    tzdata \
    shadow \
    gcompat \
    libstdc++ \
    && rm -rf /var/cache/apk/*

# Configurar timezone
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Criar usuário não-root
RUN addgroup -g $USER_GID $USERNAME && \
    adduser -D -u $USER_UID -G $USERNAME -s /bin/bash $USERNAME

# Baixar e instalar VS Code CLI
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        VS_ARCH="x64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        VS_ARCH="arm64"; \
    else \
        echo "Arquitetura não suportada: $ARCH" && exit 1; \
    fi && \
    curl -Lk "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-${VS_ARCH}" \
        --output /tmp/vscode_cli.tar.gz && \
    tar -xzf /tmp/vscode_cli.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/code && \
    rm /tmp/vscode_cli.tar.gz

# Criar diretórios necessários
RUN mkdir -p /workspace \
             /home/$USERNAME/.vscode-server \
             /home/$USERNAME/.vscode-server/extensions \
             /home/$USERNAME/.cache \
             /home/$USERNAME/.config && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME /workspace

# Copiar arquivos de configuração se existirem
COPY --chown=$USERNAME:$USERNAME config/ /home/$USERNAME/.config/

# Copiar scripts
COPY --chown=root:root scripts/install-extensions.sh /usr/local/bin/install-extensions.sh
COPY --chown=root:root scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

# Tornar scripts executáveis
RUN chmod +x /usr/local/bin/install-extensions.sh /usr/local/bin/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

# Mudar para usuário não-root
USER $USERNAME

# Diretório de trabalho
WORKDIR /workspace

# Portas expostas
EXPOSE 8000 8080

# Comando padrão
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
