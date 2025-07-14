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

# 2. Configure as variáveis de ambiente (IMPORTANTE!)
cp .env.example .env

# Edite o .env com suas configurações:
# - TUNNEL_NAME: deve ser globalmente único!
# - TZ: seu timezone
# - USER_UID/USER_GID: seus IDs (execute: id -u && id -g)
# - VSCODE_PORT: porta desejada (padrão: 8000)
nano .env  # ou vim .env

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

## 📊 Configurações e Variáveis de Ambiente

### 🔧 Variáveis de Ambiente para Parametrização

O projeto utiliza variáveis de ambiente para permitir personalização completa sem necessidade de modificar arquivos de configuração. Todas as variáveis podem ser definidas no arquivo `.env` (copie de `.env.example`).

#### **Portas de Rede**

| Variável | Padrão | Descrição | Exemplo |
|----------|--------|-----------|---------|
| `VSCODE_PORT` | `8000` | Porta HTTP para acesso via browser local | `8000`, `9000`, `3000` |
| `TUNNEL_PORT` | `8080` | Porta interna do VS Code Tunnel | `8080`, `8443`, `9080` |

```bash
# Configuração de portas
VSCODE_PORT=8000        # Acesso local: http://localhost:8000
TUNNEL_PORT=8080        # Porta interna do tunnel
```

**Importante:** A `VSCODE_PORT` deve estar disponível no host. Verifique com `netstat -tlnp | grep 8000`.

#### **Usuário e Permissões**

| Variável | Padrão | Descrição | Como obter |
|----------|--------|-----------|------------|
| `USER_UID` | `1000` | ID numérico do usuário host | `id -u` |
| `USER_GID` | `1000` | ID numérico do grupo host | `id -g` |

```bash
# Obter seus IDs (execute no host)
echo "USER_UID=$(id -u)"     # Ex: USER_UID=1001
echo "USER_GID=$(id -g)"     # Ex: USER_GID=1001

# Configuração no .env
USER_UID=1001               # Evita problemas de permissão
USER_GID=1001               # Arquivos criados com owner correto
```

**Por que isso é importante:**
- Evita problemas de permissão nos arquivos criados no container
- Garante que você possa editar arquivos criados pelo VS Code
- Mantém compatibilidade entre host e container

#### **Nome do Tunnel (Crítico)**

| Variável | Padrão | Descrição | Requisitos |
|----------|--------|-----------|------------|
| `TUNNEL_NAME` | `meu-dev-tunnel` | Nome único global do tunnel | Deve ser globalmente único |

```bash
# O nome deve ser ÚNICO GLOBALMENTE no VS Code Tunnel
TUNNEL_NAME=joao-recife-dev          # ✅ Único e descritivo
TUNNEL_NAME=empresa-backend-tunnel   # ✅ Identificação clara
TUNNEL_NAME=projeto-xyz-dev          # ✅ Específico do projeto

# Evite nomes genéricos (provavelmente já existem)
TUNNEL_NAME=dev                      # ❌ Muito genérico
TUNNEL_NAME=test                     # ❌ Provável conflito
TUNNEL_NAME=tunnel                   # ❌ Muito comum
```

**Estratégias para nomes únicos:**
- Use seu username: `usuario-dev-tunnel`
- Inclua localização: `recife-workspace-dev`
- Adicione timestamp: `dev-$(date +%Y%m%d%H%M)`
- Combine projeto + usuario: `projeto-joao-dev`

#### **Timezone (Fuso Horário)**

| Variável | Padrão | Descrição | Formatos |
|----------|--------|-----------|----------|
| `TZ` | `America/Sao_Paulo` | Timezone do container | Formato: `Continente/Cidade` |

```bash
# Timezones brasileiros
TZ=America/Sao_Paulo    # UTC-3 (São Paulo, Rio, Brasília)
TZ=America/Recife       # UTC-3 (Recife, Fortaleza, Salvador)
TZ=America/Manaus       # UTC-4 (Manaus, Amazonas)
TZ=America/Rio_Branco   # UTC-5 (Rio Branco, Acre)

# Timezones internacionais comuns
TZ=UTC                  # UTC+0 (Tempo Universal)
TZ=Europe/London        # UTC+0/+1 (Londres)
TZ=America/New_York     # UTC-5/-4 (Nova York)
TZ=Asia/Tokyo           # UTC+9 (Tóquio)
TZ=Europe/Berlin        # UTC+1/+2 (Berlim)
```

**Para encontrar seu timezone:**
```bash
# No Linux
timedatectl show --property=Timezone --value
# ou
cat /etc/timezone

# Lista completa de timezones
timedatectl list-timezones | grep America
```

#### **Configurações de Proxy (Empresarial)**

| Variável | Padrão | Descrição | Quando usar |
|----------|--------|-----------|-------------|
| `HTTP_PROXY` | - | Proxy para tráfego HTTP | Redes corporativas |
| `HTTPS_PROXY` | - | Proxy para tráfego HTTPS | Redes corporativas |
| `NO_PROXY` | - | Hosts que ignoram proxy | IPs/domínios internos |

```bash
# Configuração de proxy corporativo
HTTP_PROXY=http://proxy.empresa.com:8080
HTTPS_PROXY=http://proxy.empresa.com:8080
NO_PROXY=localhost,127.0.0.1,*.empresa.local

# Com autenticação
HTTP_PROXY=http://usuario:senha@proxy.empresa.com:8080
HTTPS_PROXY=http://usuario:senha@proxy.empresa.com:8080
```

#### **Configurações de Display (GUI)**

| Variável | Padrão | Descrição | Quando usar |
|----------|--------|-----------|-------------|
| `DISPLAY` | - | Display X11 para aplicações GUI | Debugging de GUI |

```bash
# Para executar aplicações gráficas no container
DISPLAY=:0                  # Display local
DISPLAY=host.docker.internal:0  # macOS/Windows com Docker
```

### 📋 Exemplo Completo do Arquivo .env

```bash
# =======================================================
# VS Code Tunnel Pod - Configuração Personalizada
# =======================================================

# ------------------ PORTAS ------------------
# Porta para acesso via browser (http://localhost:VSCODE_PORT)
VSCODE_PORT=8000

# Porta interna do tunnel (geralmente não precisa alterar)
TUNNEL_PORT=8080

# ------------------ USUÁRIO ------------------
# IDs do usuário/grupo (obtidos com: id -u && id -g)
USER_UID=1000
USER_GID=1000

# ------------------ TUNNEL ------------------
# Nome ÚNICO do tunnel (crítico - deve ser globalmente único!)
# Sugestões: use seu-username-projeto ou empresa-usuario-dev
TUNNEL_NAME=joao-recife-backend-dev

# ------------------ TIMEZONE ------------------
# Fuso horário (formato: Continente/Cidade)
TZ=America/Recife

# ------------------ PROXY (se necessário) ------------------
# Descomente se estiver em rede corporativa
#HTTP_PROXY=http://proxy.empresa.com:8080
#HTTPS_PROXY=http://proxy.empresa.com:8080
#NO_PROXY=localhost,127.0.0.1,*.empresa.local

# ------------------ DISPLAY (se necessário) ------------------
# Descomente para suporte a aplicações gráficas
#DISPLAY=:0

# ------------------ RECURSOS ------------------
# Limites de recursos (Docker Compose)
MEMORY_LIMIT=2g
CPU_LIMIT=2.0
MEMORY_RESERVATION=512m
CPU_RESERVATION=0.5
```

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

> **💡 Dica:** Todas as configurações abaixo são feitas através das **variáveis de ambiente** documentadas na seção anterior. Copie `.env.example` para `.env` e personalize conforme necessário.

### 🎯 Configuração Rápida

```bash
# 1. Copie o arquivo de exemplo
cp .env.example .env

# 2. Obtenha seus IDs de usuário
echo "USER_UID=$(id -u)" >> .env
echo "USER_GID=$(id -g)" >> .env

# 3. Defina um nome único para seu tunnel
echo "TUNNEL_NAME=$(whoami)-$(hostname)-dev" >> .env

# 4. Configure seu timezone
echo "TZ=$(timedatectl show --property=Timezone --value)" >> .env
```

### 🔧 Personalizações Comuns

#### **Alterar Porta de Acesso**
```bash
# No arquivo .env
VSCODE_PORT=9000    # Mudará acesso para http://localhost:9000
```

#### **Usar em Ambiente Corporativo**
```bash
# Configure proxy no .env
HTTP_PROXY=http://proxy.empresa.com:8080
HTTPS_PROXY=http://proxy.empresa.com:8080
NO_PROXY=localhost,127.0.0.1,*.empresa.local
```

#### **Múltiplos Ambientes**
```bash
# Crie arquivos .env específicos
cp .env.example .env.dev
cp .env.example .env.prod

# Use com Docker Compose
podman-compose --env-file .env.dev up -d
podman-compose --env-file .env.prod up -d
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

### ⚠️ Problemas com Variáveis de Ambiente

#### **1. Nome do Tunnel já existe**
```bash
# Erro: "tunnel name already exists"
# Solução: Use um nome mais específico
TUNNEL_NAME=$(whoami)-$(hostname)-$(date +%Y%m%d)-dev
```

#### **2. Problemas de Permissão de Arquivos**
```bash
# Verifique se USER_UID/USER_GID estão corretos
id -u && id -g

# Corrija no .env se necessário
USER_UID=1001
USER_GID=1001

# Recrie o container
podman-compose down && podman-compose up -d
```

#### **3. Timezone não funciona**
```bash
# Verifique o timezone no container
podman exec vscode-tunnel date

# Formatos válidos (exemplos)
TZ=America/Sao_Paulo    # ✅ Correto
TZ=Brazil/East          # ❌ Deprecated
TZ=GMT-3                # ❌ Não recomendado

# Liste timezones disponíveis
podman exec vscode-tunnel find /usr/share/zoneinfo -type f | head -20
```

#### **4. Porta já em uso**
```bash
# Verifique qual processo usa a porta
sudo netstat -tlnp | grep 8000
# ou
sudo lsof -i :8000

# Use outra porta no .env
VSCODE_PORT=9000
```

#### **5. Problemas de Proxy**
```bash
# Teste conectividade dentro do container
podman exec vscode-tunnel curl -v https://github.com

# Configure corretamente no .env
HTTP_PROXY=http://proxy.empresa.com:8080
HTTPS_PROXY=http://proxy.empresa.com:8080
NO_PROXY=localhost,127.0.0.1
```

### 🔍 Comandos de Diagnóstico

#### **Verificar Configuração Atual**
```bash
# Ver variáveis de ambiente carregadas
podman exec vscode-tunnel env | grep -E "(TUNNEL_NAME|TZ|USER_|VSCODE_|HTTP_)"

# Verificar usuário no container
podman exec vscode-tunnel id

# Verificar timezone
podman exec vscode-tunnel date
```

#### **Validar Arquivo .env**
```bash
# Verificar sintaxe do .env
cat .env | grep -v '^#' | grep -v '^$'

# Testar variáveis
source .env && echo "TUNNEL_NAME: $TUNNEL_NAME, TZ: $TZ"
```

### 🚨 Problemas Comuns e Soluções

#### **Container não inicia**

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

### ✅ Validação da Configuração

#### **Script de Validação Rápida**
```bash
#!/bin/bash
# validate-config.sh - Valida configuração antes do deploy

echo "🔍 Validando configuração do VS Code Tunnel..."

# Verificar arquivo .env
if [[ ! -f ".env" ]]; then
    echo "❌ Arquivo .env não encontrado. Copie de .env.example"
    exit 1
fi

source .env

# Validar variáveis obrigatórias
required_vars=("TUNNEL_NAME" "TZ" "USER_UID" "USER_GID" "VSCODE_PORT")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Variável $var não definida no .env"
        exit 1
    fi
done

# Validar formato do timezone
if ! timedatectl list-timezones | grep -q "^$TZ$"; then
    echo "⚠️  Timezone '$TZ' pode não ser válido"
fi

# Verificar se porta está disponível
if netstat -tlnp 2>/dev/null | grep -q ":$VSCODE_PORT "; then
    echo "⚠️  Porta $VSCODE_PORT já está em uso"
fi

# Verificar IDs de usuário
if [[ "$USER_UID" != "$(id -u)" ]] || [[ "$USER_GID" != "$(id -g)" ]]; then
    echo "⚠️  USER_UID/USER_GID diferem do usuário atual"
    echo "   Atual: $(id -u):$(id -g), Configurado: $USER_UID:$USER_GID"
fi

echo "✅ Configuração validada!"
echo "📋 Resumo:"
echo "   🏷️  Tunnel: $TUNNEL_NAME"
echo "   🌍 Timezone: $TZ"
echo "   👤 User: $USER_UID:$USER_GID"
echo "   🔌 Port: $VSCODE_PORT"
```

#### **Testar Conectividade**
```bash
# Após iniciar o container, teste a conectividade
curl -f http://localhost:${VSCODE_PORT:-8000}/healthz || echo "❌ Falha na conectividade"

# Verificar se o tunnel está registrado
podman exec vscode-tunnel code tunnel status
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

### 📋 Como Contribuir

1. **Fork o projeto**
2. **Crie uma branch para sua feature**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Teste suas mudanças**
   ```bash
   # Valide as configurações
   ./validate-config.sh

   # Teste com diferentes .env
   cp .env.example .env.test
   # ... edite .env.test
   podman-compose --env-file .env.test up -d
   ```
4. **Commit suas mudanças**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
5. **Push para a branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
6. **Abra um Pull Request**

### 🔧 Boas Práticas para Contribuições

#### **Adicionando Novas Variáveis de Ambiente**
- Adicione a variável em `.env.example` com valor padrão
- Documente na seção "Variáveis de Ambiente para Parametrização"
- Inclua validação no script de diagnóstico
- Adicione exemplo de uso prático

#### **Modificando Configurações**
- Sempre use variáveis de ambiente em vez de valores hardcoded
- Mantenha compatibilidade com configurações existentes
- Teste com diferentes valores das variáveis

#### **Documentação**
- Mantenha o README.md atualizado
- Inclua exemplos práticos de uso
- Documente troubleshooting para novos recursos

### 📖 FAQ - Variáveis de Ambiente

#### **P: Como saber se meu TUNNEL_NAME é único?**
R: Execute o container e veja os logs. Se aparecer "tunnel name already exists", mude o nome. Use formatos como `usuario-projeto-dev` ou `empresa-usuario-$(date +%Y%m%d)`.

#### **P: Posso usar o mesmo TUNNEL_NAME em múltiplas máquinas?**
R: Não! Cada instância precisa de um nome único. Use sufixos como `-desktop`, `-laptop`, `-servidor`.

#### **P: Como alterar as configurações depois do container criado?**
R: Edite o `.env`, depois recrie o container:
```bash
podman-compose down
podman-compose up -d
```

#### **P: As variáveis de ambiente são sensíveis à segurança?**
R: O `.env` pode conter informações sensíveis (proxies com credenciais). Sempre adicione `.env` ao `.gitignore` e use `.env.example` para templates.

#### **P: Posso usar variáveis do sistema operacional?**
R: Sim! Exemplo:
```bash
# No .env
TUNNEL_NAME=${USER}-dev-tunnel
TZ=$(timedatectl show --property=Timezone --value)
```

#### **P: Como usar em CI/CD?**
R: Defina as variáveis no pipeline:
```bash
export TUNNEL_NAME="ci-build-${BUILD_NUMBER}"
export TZ="UTC"
podman-compose up -d
```

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
