# VS Code Tunnel Podman

Este projeto configura um container Podman para executar o VS Code Tunnel, permitindo acesso remoto ao VS Code através do navegador, compartilhando apenas a pasta `~/src` do host.

## 📋 Pré-requisitos

- [Podman](https://podman.io/) instalado no sistema
- Conta Microsoft ou GitHub para autenticação do VS Code Tunnel
- Pasta `~/src` existente no sistema host

## 🚀 Início Rápido

### Opção 1: Docker/Podman Compose (Recomendado)

```bash
# 1. Clone o repositório
git clone <url-do-repositorio>
cd vscodetunnelpod

# 2. Configure as variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env conforme necessário

# 3. Inicie o pod
podman-compose up -d
# ou
docker-compose up -d
```

### Opção 2: Podman Quadlet (Systemd)

```bash
# 1. Copie os arquivos para o systemd do usuário
mkdir -p ~/.config/containers/systemd
cp vscode-tunnel.pod ~/.config/containers/systemd/
cp vscode-tunnel.container ~/.config/containers/systemd/

# 2. Recarregue o systemd e inicie
systemctl --user daemon-reload
systemctl --user start vscode-tunnel.service
systemctl --user enable vscode-tunnel.service
```

### Opção 3: Scripts Tradicionais

```bash
# 1. Execute o script de setup
./setup.sh

# 2. Inicie o container
./start.sh
```

### Opção 4: Kubernetes

```bash
# Aplique a configuração Kubernetes
kubectl apply -f kubernetes.yml
```

## 📁 Estrutura do Projeto

```
vscodetunnelpod/
├── README.md                  # Este arquivo
├── Containerfile              # Definição da imagem do container
├── docker-compose.yml         # Configuração Docker/Podman Compose
├── vscode-tunnel.pod          # Configuração Podman Quadlet (Pod)
├── vscode-tunnel.container    # Configuração Podman Quadlet (Container)
├── kubernetes.yml             # Configuração Kubernetes
├── .env                      # Variáveis de ambiente (para teste)
├── .env.example              # Exemplo de variáveis de ambiente
├── .gitignore                # Arquivos ignorados pelo Git
├── setup.sh                  # Script de configuração inicial
├── start.sh                  # Script para iniciar o container
├── stop.sh                   # Script para parar o container
└── config/                   # Arquivos de configuração
    ├── .gitkeep              # Documentação da pasta
    └── extensions.txt        # Lista de extensões VS Code
```

## 🔧 Configuração

### Containerfile

O container é baseado numa imagem Ubuntu/Alpine com:
- VS Code CLI instalado
- Dependências necessárias
- Usuário não-root para segurança
- Volume montado em `/workspace` apontando para `~/src`

### Volumes

- `~/src` (host) → `/workspace` (container): Pasta de desenvolvimento compartilhada
- `vscode-tunnel-data`: Volume persistente para dados do VS Code

### Rede

- Porta 8000 exposta para acesso web (configurável)
- Modo bridge para isolamento de rede

## 📋 Métodos de Inicialização

### 1. Docker/Podman Compose (docker-compose.yml)

**Vantagens:**
- Configuração declarativa simples
- Gerenciamento de volumes automático
- Suporte nativo no Podman e Docker
- Ideal para desenvolvimento local

**Uso:**
```bash
podman-compose up -d        # Iniciar em background
podman-compose logs -f      # Ver logs
podman-compose down         # Parar e remover
```

### 2. Podman Quadlet (Systemd)

**Vantagens:**
- Integração nativa com systemd
- Inicialização automática no boot
- Logs centralizados via journalctl
- Gerenciamento via systemctl

**Arquivos:**
- `vscode-tunnel.pod` - Configuração do pod
- `vscode-tunnel.container` - Configuração do container

**Uso:**
```bash
systemctl --user start vscode-tunnel.service
systemctl --user status vscode-tunnel.service
journalctl --user -u vscode-tunnel.service -f
```

### 3. Kubernetes (kubernetes.yml)

**Vantagens:**
- Escalabilidade e alta disponibilidade
- Ingress para acesso externo
- Persistent Volumes para dados
- Health checks automáticos

**Componentes incluídos:**
- Namespace dedicado
- ConfigMap para configurações
- PersistentVolumeClaims para dados
- Deployment com health checks
- Service para acesso interno
- Ingress para acesso externo

## 📊 Configurações YAML

### Variáveis de Ambiente Principais

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `VSCODE_PORT` | 8000 | Porta para acesso web |
| `TUNNEL_PORT` | 8080 | Porta do tunnel |
| `USER_UID` | 1000 | ID do usuário |
| `USER_GID` | 1000 | ID do grupo |
| `TUNNEL_NAME` | dev-tunnel | Nome único do tunnel |
| `VSCODE_SERVE_MODE` | serve-web | Modo de operação |

### Volumes Configurados

| Volume | Destino | Propósito |
|--------|---------|-----------|
| `~/src` | `/workspace` | Código fonte compartilhado |
| `vscode-data` | `/home/vscode/.vscode-server` | Dados do VS Code Server |
| `vscode-extensions` | `/home/vscode/.vscode-server/extensions` | Extensões instaladas |
| `vscode-cache` | `/home/vscode/.cache` | Cache do sistema |
| `vscode-config` | `/home/vscode/.config` | Configurações do usuário |

### Recursos e Limites

**Docker Compose:**
- Memória: 512MB-2GB
- CPU: 0.5-2.0 cores

**Kubernetes:**
- Requests: 512MB RAM, 0.5 CPU
- Limits: 2GB RAM, 2.0 CPU

## 🛠️ Scripts Disponíveis

### `setup.sh`
Configura o ambiente inicial:
- Constrói a imagem do container
- Cria volumes necessários
- Verifica dependências

### `start.sh`
Inicia o container VS Code Tunnel:
- Monta o volume `~/src`
- Configura portas de rede
- Inicia o tunnel em modo daemon

### `stop.sh`
Para o container e limpa recursos:
- Para o container graciosamente
- Remove container temporário
- Mantém volumes de dados

## 🌐 Acesso ao VS Code

Após iniciar o container, você pode acessar o VS Code de duas formas:

### 1. Via Browser Local
```
http://localhost:8000
```

### 2. Via VS Code Tunnel (Remoto)
1. Execute o comando de autenticação mostrado nos logs
2. Acesse https://vscode.dev/tunnel
3. Faça login com sua conta Microsoft/GitHub
4. Selecione seu tunnel na lista

## ⚙️ Configurações Avançadas

### Personalizar Porta

Edite o arquivo `.env` ou modifique `start.sh`:

```bash
# Alterar porta padrão 8000
export VSCODE_PORT=9000
```

### Adicionar Extensões

Crie um arquivo `extensions.txt` com as extensões desejadas:

```
ms-python.python
ms-vscode.vscode-typescript-next
esbenp.prettier-vscode
```

### Configurar Proxy

Para uso em ambientes corporativos, configure as variáveis de ambiente:

```bash
export HTTP_PROXY=http://proxy.empresa.com:8080
export HTTPS_PROXY=http://proxy.empresa.com:8080
```

## 🔒 Segurança

### Práticas Implementadas

- Container executa com usuário não-root
- Apenas pasta `~/src` é montada (isolamento do filesystem)
- Rede em modo bridge (isolamento de rede)
- Volumes com permissões restritas

### Recomendações

- Use autenticação forte (2FA) na conta Microsoft/GitHub
- Mantenha o Podman atualizado
- Monitore logs regularmente: `podman logs vscode-tunnel`

## 🐛 Solução de Problemas

### Container não inicia

```bash
# Verificar logs
podman logs vscode-tunnel

# Verificar se a porta está em uso
netstat -tlnp | grep 8000

# Recriar container
./stop.sh && ./start.sh
```

### Problemas de Permissão

```bash
# Verificar permissões da pasta ~/src
ls -la ~/src

# Ajustar se necessário
chmod 755 ~/src
```

### Tunnel não aparece online

```bash
# Verificar autenticação
podman exec -it vscode-tunnel code tunnel user show

# Re-autenticar se necessário
podman exec -it vscode-tunnel code tunnel user login
```

## 📊 Monitoramento

### Verificar Status

```bash
# Status do container
podman ps | grep vscode-tunnel

# Uso de recursos
podman stats vscode-tunnel

# Logs em tempo real
podman logs -f vscode-tunnel
```

### Backup de Configurações

```bash
# Backup do volume de dados
podman volume export vscode-tunnel-data > vscode-backup-$(date +%Y%m%d).tar

# Restaurar backup
podman volume import vscode-tunnel-data vscode-backup-20250713.tar
```

## 🔄 Atualizações

### Atualizar VS Code

```bash
# Parar container
./stop.sh

# Reconstruir imagem
podman build -t vscode-tunnel:latest .

# Reiniciar
./start.sh
```

### Atualizar Sistema

```bash
# Atualizar Podman
sudo dnf update podman  # Fedora/RHEL
sudo apt update && sudo apt upgrade podman  # Ubuntu/Debian
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- [VS Code](https://code.visualstudio.com/) pela excelente ferramenta
- [Podman](https://podman.io/) pela alternativa segura ao Docker
- Comunidade open source pelos exemplos e inspiração

## 📞 Suporte

- 🐛 [Issues](https://github.com/seu-usuario/vscodetunnelpod/issues)
- 💬 [Discussions](https://github.com/seu-usuario/vscodetunnelpod/discussions)
- 📧 Email: seu-email@exemplo.com

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!
