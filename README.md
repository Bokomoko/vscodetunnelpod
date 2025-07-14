# VS Code Tunnel Podman

This project configures a Podman container to run VS Code Tunnel, allowing remote access to VS Code through the browser, sharing only the host's `~/src` folder.

## 📋 Prerequisites

- [Podman](https://podman.io/) installed on the system
- Microsoft or GitHub account for VS Code Tunnel authentication
- Source code directory (default: `~/src`) existing on the host system

### 🪟 Windows Users

**Recommended:** Use [WSL2 (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/) for the best experience:

1. **Install WSL2:**
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   # Restart your computer
   ```

2. **Install Podman in WSL2:**
   ```bash
   # Inside WSL2 terminal
   sudo apt update
   sudo apt install podman
   ```

3. **Create source directory:**
   ```bash
   mkdir -p ~/src
   ```

4. **Access from VS Code:**
   - Install the "WSL" extension in VS Code
   - Use `code .` from WSL2 terminal or connect via Remote-WSL

**Alternative for Windows:** Docker Desktop with Podman compatibility, but WSL2 is strongly recommended for better performance and compatibility.

## 🚀 Quick Start

### Option 1: Docker/Podman Compose (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/Bokomoko/vscodetunnelpod.git
cd vscodetunnelpod

# 2. Configure environment variables (IMPORTANT!)
cp .env.example .env

# Edit the .env with your settings:
# - TUNNEL_NAME: must be globally unique!
# - TZ: your timezone
# - USER_UID/USER_GID: your IDs (run: id -u && id -g) - defaults to 1000:1000
# - SOURCE_DIR: source directory to share (defaults to ~/src)
# - VSCODE_PORT: desired port (default: 8000)
nano .env  # or vim .env

# 3. Start the pod
podman-compose up -d
# or
docker-compose up -d
```

### Option 2: Podman Quadlet (Systemd)

```bash
# 1. Copy files to user systemd
mkdir -p ~/.config/containers/systemd
cp vscode-tunnel.pod ~/.config/containers/systemd/
cp vscode-tunnel.container ~/.config/containers/systemd/

# 2. Reload systemd and start
systemctl --user daemon-reload
systemctl --user start vscode-tunnel.service
systemctl --user enable vscode-tunnel.service
```

### Option 3: Traditional Scripts

```bash
# 1. Run setup script
./setup.sh

# 2. Start the container
./start.sh
```

### Option 4: Kubernetes

```bash
# Apply Kubernetes configuration
kubectl apply -f kubernetes.yml
```

## 📁 Project Structure

```
vscodetunnelpod/
├── README.md                  # This file
├── Containerfile              # Container image definition
├── docker-compose.yml         # Docker/Podman Compose configuration
├── vscode-tunnel.pod          # Podman Quadlet configuration (Pod)
├── vscode-tunnel.container    # Podman Quadlet configuration (Container)
├── kubernetes.yml             # Kubernetes configuration
├── .env                      # Environment variables (for testing)
├── .env.example              # Environment variables example
├── .gitignore                # Files ignored by Git
├── setup.sh                  # Initial setup script
├── start.sh                  # Script to start the container
├── stop.sh                   # Script to stop the container
└── config/                   # Configuration files
    ├── .gitkeep              # Folder documentation
    └── extensions.txt        # VS Code extensions list
```

## 🔧 Configuration

### Containerfile

The container is based on an Ubuntu/Alpine image with:
- VS Code CLI installed
- Required dependencies
- Non-root user for security
- Volume mounted at `/workspace` pointing to `SOURCE_DIR` (default: `~/src`)

### Volumes

- `SOURCE_DIR` (host) → `/workspace` (container): Shared development folder (configurable)
- `vscode-tunnel-data`: Persistent volume for VS Code data

### Network

- Port 8000 exposed for web access (configurable)
- Bridge mode for network isolation

## 📋 Initialization Methods

### 1. Docker/Podman Compose (docker-compose.yml)

**Advantages:**
- Simple declarative configuration
- Automatic volume management
- Native support in Podman and Docker
- Ideal for local development

**Usage:**
```bash
podman-compose up -d        # Start in background
podman-compose logs -f      # View logs
podman-compose down         # Stop and remove
```

### 2. Podman Quadlet (Systemd)

**Advantages:**
- Native systemd integration
- Automatic startup on boot
- Centralized logs via journalctl
- Management via systemctl

**Files:**
- `vscode-tunnel.pod` - Pod configuration
- `vscode-tunnel.container` - Container configuration

**Usage:**
```bash
systemctl --user start vscode-tunnel.service
systemctl --user status vscode-tunnel.service
journalctl --user -u vscode-tunnel.service -f
```

### 3. Kubernetes (kubernetes.yml)

**Advantages:**
- Scalability and high availability
- Ingress for external access
- Persistent Volumes for data
- Automatic health checks

**Included components:**
- Dedicated namespace
- ConfigMap for configurations
- PersistentVolumeClaims for data
- Deployment with health checks
- Service for internal access
- Ingress for external access

## 📊 Configuration and Environment Variables

### 🔧 Environment Variables for Parameterization

The project uses environment variables to allow complete customization without the need to modify configuration files. All variables can be defined in the `.env` file (copy from `.env.example`).

#### **Network Ports**

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `VSCODE_PORT` | `8000` | HTTP port for local browser access | `8000`, `9000`, `3000` |
| `TUNNEL_PORT` | `8080` | Internal port for VS Code Tunnel | `8080`, `8443`, `9080` |

```bash
# Port configuration
VSCODE_PORT=8000        # Local access: http://localhost:8000
TUNNEL_PORT=8080        # Internal tunnel port
```

**Important:** The `VSCODE_PORT` must be available on the host. Check with `netstat -tlnp | grep 8000`.

#### **User and Permissions**

| Variable | Default | Description | How to get |
|----------|---------|-------------|------------|
| `USER_UID` | `1000` | Host user numeric ID | `id -u` |
| `USER_GID` | `1000` | Host group numeric ID | `id -g` |

```bash
# Get your IDs (run on host)
echo "USER_UID=$(id -u)"     # Ex: USER_UID=1001
echo "USER_GID=$(id -g)"     # Ex: USER_GID=1001

# Configuration in .env (defaults to 1000:1000)
USER_UID=1000               # Default: 1000 (most Linux users)
USER_GID=1000               # Default: 1000 (most Linux users)
```

**Why this is important:**
- Avoids permission issues with files created in the container
- Ensures you can edit files created by VS Code
- Maintains compatibility between host and container
- Default 1000:1000 works for most single-user Linux systems

#### **Source Directory**

| Variable | Default | Description | Requirements |
|----------|---------|-------------|--------------|
| `SOURCE_DIR` | `~/src` | Host directory to share with container | Must exist and be readable |

```bash
# Source directory configuration
SOURCE_DIR=~/src                    # Default: user's src folder
SOURCE_DIR=/home/user/projects      # Custom projects directory
SOURCE_DIR=/mnt/d/code              # WSL2: Windows D: drive
SOURCE_DIR=/workspace               # Custom workspace location
```

**Path examples by system:**
- **Linux:** `~/src`, `/home/username/projects`, `/opt/workspace`
- **WSL2:** `~/src`, `/mnt/c/Users/username/src`, `/mnt/d/projects`
- **macOS:** `~/src`, `/Users/username/code`, `/opt/development`

#### **Tunnel Name (Critical)**

| Variable | Default | Description | Requirements |
|----------|---------|-------------|--------------|
| `TUNNEL_NAME` | `my-dev-tunnel` | Globally unique tunnel name | Must be globally unique |

```bash
# The name must be GLOBALLY UNIQUE in VS Code Tunnel
TUNNEL_NAME=john-recife-dev          # ✅ Unique and descriptive
TUNNEL_NAME=company-backend-tunnel   # ✅ Clear identification
TUNNEL_NAME=project-xyz-dev          # ✅ Project specific

# Avoid generic names (probably already exist)
TUNNEL_NAME=dev                      # ❌ Too generic
TUNNEL_NAME=test                     # ❌ Likely conflict
TUNNEL_NAME=tunnel                   # ❌ Too common
```

**Strategies for unique names:**
- Use your username: `user-dev-tunnel`
- Include location: `recife-workspace-dev`
- Add timestamp: `dev-$(date +%Y%m%d%H%M)`
- Combine project + user: `project-john-dev`

#### **Timezone**

| Variable | Default | Description | Formats |
|----------|---------|-------------|---------|
| `TZ` | `America/Sao_Paulo` | Container timezone | Format: `Continent/City` |

```bash
# Brazilian timezones
TZ=America/Sao_Paulo    # UTC-3 (São Paulo, Rio, Brasília)
TZ=America/Recife       # UTC-3 (Recife, Fortaleza, Salvador)
TZ=America/Manaus       # UTC-4 (Manaus, Amazonas)
TZ=America/Rio_Branco   # UTC-5 (Rio Branco, Acre)

# Common international timezones
TZ=UTC                  # UTC+0 (Universal Time)
TZ=Europe/London        # UTC+0/+1 (London)
TZ=America/New_York     # UTC-5/-4 (New York)
TZ=Asia/Tokyo           # UTC+9 (Tokyo)
TZ=Europe/Berlin        # UTC+1/+2 (Berlin)
```

**To find your timezone:**
```bash
# On Linux
timedatectl show --property=Timezone --value
# or
cat /etc/timezone

# Complete list of timezones
timedatectl list-timezones | grep America
```

#### **Proxy Settings (Corporate)**

| Variable | Default | Description | When to use |
|----------|---------|-------------|-------------|
| `HTTP_PROXY` | - | Proxy for HTTP traffic | Corporate networks |
| `HTTPS_PROXY` | - | Proxy for HTTPS traffic | Corporate networks |
| `NO_PROXY` | - | Hosts that bypass proxy | Internal IPs/domains |

```bash
# Corporate proxy configuration
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,*.company.local

# With authentication
HTTP_PROXY=http://user:password@proxy.company.com:8080
HTTPS_PROXY=http://user:password@proxy.company.com:8080
```

#### **Display Settings (GUI)**

| Variable | Default | Description | When to use |
|----------|---------|-------------|-------------|
| `DISPLAY` | - | X11 display for GUI applications | GUI debugging |

```bash
# To run graphical applications in container
DISPLAY=:0                  # Local display
DISPLAY=host.docker.internal:0  # macOS/Windows with Docker
```

### 📋 Complete .env File Example

```bash
# =======================================================
# VS Code Tunnel Pod - Custom Configuration
# =======================================================

# ------------------ PORTS ------------------
# Port for browser access (http://localhost:VSCODE_PORT)
VSCODE_PORT=8000

# Internal tunnel port (usually doesn't need to change)
TUNNEL_PORT=8080

# ------------------ USER ------------------
# User/group IDs (obtained with: id -u && id -g)
# Default 1000:1000 works for most single-user Linux systems
USER_UID=1000
USER_GID=1000

# ------------------ SOURCE DIRECTORY ------------------
# Directory to share with container (must exist on host)
# Examples: ~/src, /home/user/projects, /mnt/c/code (WSL2)
SOURCE_DIR=~/src

# ------------------ TUNNEL ------------------
# UNIQUE tunnel name (critical - must be globally unique!)
# Suggestions: use your-username-project or company-user-dev
TUNNEL_NAME=john-recife-backend-dev

# ------------------ TIMEZONE ------------------
# Timezone (format: Continent/City)
TZ=America/Recife

# ------------------ PROXY (if needed) ------------------
# Uncomment if on corporate network
#HTTP_PROXY=http://proxy.company.com:8080
#HTTPS_PROXY=http://proxy.company.com:8080
#NO_PROXY=localhost,127.0.0.1,*.company.local

# ------------------ DISPLAY (if needed) ------------------
# Uncomment for GUI application support
#DISPLAY=:0

# ------------------ RESOURCES ------------------
# Resource limits (Docker Compose)
MEMORY_LIMIT=2g
CPU_LIMIT=2.0
MEMORY_RESERVATION=512m
CPU_RESERVATION=0.5
```

### Configured Volumes

| Volume | Destination | Purpose |
|--------|-------------|---------|
| `SOURCE_DIR` | `/workspace` | Shared source code (configurable path) |
| `vscode-data` | `/home/vscode/.vscode-server` | VS Code Server data |
| `vscode-extensions` | `/home/vscode/.vscode-server/extensions` | Installed extensions |
| `vscode-cache` | `/home/vscode/.cache` | System cache |
| `vscode-config` | `/home/vscode/.config` | User configurations |

### Resources and Limits

**Docker Compose:**
- Memory: 512MB-2GB
- CPU: 0.5-2.0 cores

**Kubernetes:**
- Requests: 512MB RAM, 0.5 CPU
- Limits: 2GB RAM, 2.0 CPU

## 🛠️ Available Scripts

### `setup.sh`
Configures the initial environment:
- Builds the container image
- Creates necessary volumes
- Checks dependencies

### `start.sh`
Starts the VS Code Tunnel container:
- Mounts the `SOURCE_DIR` volume (default: `~/src`)
- Configures network ports
- Starts the tunnel in daemon mode

### `stop.sh`
Stops the container and cleans up resources:
- Stops the container gracefully
- Removes temporary container
- Keeps data volumes

## 🌐 VS Code Access

After starting the container, you can access VS Code in two ways:

### 1. Via Local Browser
```
http://localhost:8000
```

### 2. Via VS Code Tunnel (Remote)
1. Run the authentication command shown in the logs
2. Access https://vscode.dev/tunnel
3. Log in with your Microsoft/GitHub account
4. Select your tunnel from the list

## ⚙️ Advanced Settings

> **💡 Tip:** All settings below are made through the **environment variables** documented in the previous section. Copy `.env.example` to `.env` and customize as needed.

### 🎯 Quick Configuration

```bash
# 1. Copy the example file
cp .env.example .env

# 2. Get your user IDs (optional - defaults to 1000:1000)
echo "USER_UID=$(id -u)" >> .env
echo "USER_GID=$(id -g)" >> .env

# 3. Set your source directory (optional - defaults to ~/src)
echo "SOURCE_DIR=$HOME/src" >> .env  # or your preferred path

# 4. Define a unique name for your tunnel
echo "TUNNEL_NAME=$(whoami)-$(hostname)-dev" >> .env

# 5. Configure your timezone
echo "TZ=$(timedatectl show --property=Timezone --value)" >> .env
```

### 🔧 Common Customizations

#### **Change Access Port**
```bash
# In .env file
VSCODE_PORT=9000    # Will change access to http://localhost:9000
```

#### **Use in Corporate Environment**
```bash
# Configure proxy in .env
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,*.company.local
```

#### **Multiple Environments**
```bash
# Create specific .env files
cp .env.example .env.dev
cp .env.example .env.prod

# Use with Docker Compose
podman-compose --env-file .env.dev up -d
podman-compose --env-file .env.prod up -d
```

### Add Extensions

Create an `extensions.txt` file with desired extensions:

```
ms-python.python
ms-vscode.vscode-typescript-next
esbenp.prettier-vscode
```

### Configure Proxy

For corporate environments, configure the environment variables:

```bash
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

## 🔒 Security

### Implemented Practices

- Container runs with non-root user
- Only `~/src` folder is mounted (filesystem isolation)
- Network in bridge mode (network isolation)
- Volumes with restricted permissions

### Recommendations

- Use strong authentication (2FA) on Microsoft/GitHub account
- Keep Podman updated
- Monitor logs regularly: `podman logs vscode-tunnel`

## 🐛 Troubleshooting

### ⚠️ Environment Variables Issues

#### **1. Tunnel name already exists**
```bash
# Error: "tunnel name already exists"
# Solution: Use a more specific name
TUNNEL_NAME=$(whoami)-$(hostname)-$(date +%Y%m%d)-dev
```

#### **2. File Permission Issues**
```bash
# Check if USER_UID/USER_GID are correct
id -u && id -g

# Fix in .env if necessary (defaults are 1000:1000)
USER_UID=1000
USER_GID=1000

# Recreate container
podman-compose down && podman-compose up -d
```

#### **3. Source Directory Issues**
```bash
# Check if SOURCE_DIR exists and is accessible
ls -la "$SOURCE_DIR" 2>/dev/null || echo "Directory doesn't exist"

# Create directory if needed
mkdir -p ~/src  # or your custom SOURCE_DIR

# Fix permissions if necessary
chmod 755 ~/src
```

#### **4. Timezone not working**
```bash
# Check timezone in container
podman exec vscode-tunnel date

# Valid formats (examples)
TZ=America/Sao_Paulo    # ✅ Correct
TZ=Brazil/East          # ❌ Deprecated
TZ=GMT-3                # ❌ Not recommended

# List available timezones
podman exec vscode-tunnel find /usr/share/zoneinfo -type f | head -20
```

#### **5. Port already in use**
```bash
# Check which process uses the port
sudo netstat -tlnp | grep 8000
# or
sudo lsof -i :8000

# Use another port in .env
VSCODE_PORT=9000
```

#### **6. Proxy Issues**
```bash
# Test connectivity inside container
podman exec vscode-tunnel curl -v https://github.com

# Configure correctly in .env
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1
```

### 🔍 Diagnostic Commands

#### **Check Current Configuration**
```bash
# View loaded environment variables
podman exec vscode-tunnel env | grep -E "(TUNNEL_NAME|TZ|USER_|VSCODE_|HTTP_)"

# Check user in container
podman exec vscode-tunnel id

# Check timezone
podman exec vscode-tunnel date
```

#### **Validate .env File**
```bash
# Check .env syntax
cat .env | grep -v '^#' | grep -v '^$'

# Test variables
source .env && echo "TUNNEL_NAME: $TUNNEL_NAME, TZ: $TZ"
```

### 🚨 Common Issues and Solutions

#### **Container doesn't start**

```bash
# Check logs
podman logs vscode-tunnel

# Check if port is in use
netstat -tlnp | grep 8000

# Recreate container
./stop.sh && ./start.sh
```

### Permission Issues

```bash
# Check source directory permissions
ls -la "$SOURCE_DIR" 2>/dev/null || echo "SOURCE_DIR not found"

# Fix if necessary
mkdir -p ~/src  # or your SOURCE_DIR
chmod 755 ~/src
```

### Tunnel doesn't appear online

```bash
# Check authentication
podman exec -it vscode-tunnel code tunnel user show

# Re-authenticate if necessary
podman exec -it vscode-tunnel code tunnel user login
```

### ✅ Configuration Validation

#### **Quick Validation Script**
```bash
#!/bin/bash
# validate-config.sh - Validates configuration before deploy

echo "🔍 Validating VS Code Tunnel configuration..."

# Check .env file
if [[ ! -f ".env" ]]; then
    echo "❌ .env file not found. Copy from .env.example"
    exit 1
fi

source .env

# Validate required variables
required_vars=("TUNNEL_NAME" "TZ" "USER_UID" "USER_GID" "VSCODE_PORT" "SOURCE_DIR")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Variable $var not defined in .env"
        exit 1
    fi
done

# Check if SOURCE_DIR exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "❌ SOURCE_DIR '$SOURCE_DIR' does not exist"
    echo "   Create it with: mkdir -p '$SOURCE_DIR'"
    exit 1
fi

# Validate timezone format
if ! timedatectl list-timezones | grep -q "^$TZ$"; then
    echo "⚠️  Timezone '$TZ' may not be valid"
fi

# Check if port is available
if netstat -tlnp 2>/dev/null | grep -q ":$VSCODE_PORT "; then
    echo "⚠️  Port $VSCODE_PORT is already in use"
fi

# Check user IDs
if [[ "$USER_UID" != "$(id -u)" ]] || [[ "$USER_GID" != "$(id -g)" ]]; then
    echo "⚠️  USER_UID/USER_GID differ from current user"
    echo "   Current: $(id -u):$(id -g), Configured: $USER_UID:$USER_GID"
fi

echo "✅ Configuration validated!"
echo "📋 Summary:"
echo "   🏷️  Tunnel: $TUNNEL_NAME"
echo "   🌍 Timezone: $TZ"
echo "   👤 User: $USER_UID:$USER_GID"
echo "   � Source: $SOURCE_DIR"
echo "   �🔌 Port: $VSCODE_PORT"
```

#### **Test Connectivity**
```bash
# After starting the container, test connectivity
curl -f http://localhost:${VSCODE_PORT:-8000}/healthz || echo "❌ Connectivity failure"

# Check if tunnel is registered
podman exec vscode-tunnel code tunnel status
```

## 📊 Monitoring

### Check Status

```bash
# Container status
podman ps | grep vscode-tunnel

# Resource usage
podman stats vscode-tunnel

# Real-time logs
podman logs -f vscode-tunnel
```

### Configuration Backup

```bash
# Backup data volume
podman volume export vscode-tunnel-data > vscode-backup-$(date +%Y%m%d).tar

# Restore backup
podman volume import vscode-tunnel-data vscode-backup-20250713.tar
```

## 🔄 Updates

### Update VS Code

```bash
# Stop container
./stop.sh

# Rebuild image
podman build -t vscode-tunnel:latest .

# Restart
./start.sh
```

### Update System

```bash
# Update Podman
sudo dnf update podman  # Fedora/RHEL
sudo apt update && sudo apt upgrade podman  # Ubuntu/Debian
```

## � Windows Users Guide

### Using WSL2 (Recommended)

WSL2 provides the best experience for running Podman and this VS Code Tunnel setup on Windows.

#### **Initial Setup**

1. **Install WSL2:**
   ```powershell
   # Run PowerShell as Administrator
   wsl --install
   # Restart computer when prompted
   ```

2. **Update WSL2 (if already installed):**
   ```powershell
   wsl --update
   wsl --set-default-version 2
   ```

3. **Install Ubuntu (recommended):**
   ```powershell
   wsl --install -d Ubuntu
   ```

#### **Install Podman in WSL2**

```bash
# Inside WSL2 Ubuntu terminal
sudo apt update
sudo apt install -y podman

# Verify installation
podman --version
```

#### **Configure Source Directory**

```bash
# Option 1: Use WSL2 home directory (recommended)
mkdir -p ~/src
SOURCE_DIR=~/src

# Option 2: Access Windows drives
mkdir -p /mnt/c/Users/$USER/src
SOURCE_DIR=/mnt/c/Users/$USER/src

# Option 3: Use Windows D: drive
mkdir -p /mnt/d/projects
SOURCE_DIR=/mnt/d/projects
```

#### **Configure .env for WSL2**

```bash
# Example .env configuration for WSL2
cp .env.example .env

# Edit with your preferences
nano .env
```

Example WSL2 `.env`:
```bash
# WSL2 optimized configuration
USER_UID=1000
USER_GID=1000
SOURCE_DIR=/mnt/c/Users/yourusername/src  # Windows directory
TUNNEL_NAME=wsl-dev-tunnel-$(whoami)
TZ=America/New_York
VSCODE_PORT=8000
```

#### **VS Code Integration**

1. **Install VS Code Extensions:**
   - [WSL Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)
   - [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

2. **Connect to WSL2:**
   ```bash
   # From WSL2 terminal in your project directory
   code .
   ```

3. **Or connect via Command Palette:**
   - `Ctrl+Shift+P` → "WSL: Connect to WSL"

#### **Performance Tips for WSL2**

- **Use WSL2 filesystem** (`~/src`) for better performance
- **Avoid frequent cross-filesystem operations** (Windows ↔ WSL2)
- **Configure Windows Defender exclusions** for WSL2 directories
- **Allocate sufficient resources** to WSL2 via `.wslconfig`

**Example `.wslconfig`** (place in `C:\Users\%USERNAME%\.wslconfig`):
```ini
[wsl2]
memory=4GB
processors=2
swap=2GB
```

#### **Alternative: Docker Desktop**

If you prefer Docker Desktop (not recommended for best performance):

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Enable WSL2 backend in Docker Desktop settings
3. Use `docker-compose` instead of `podman-compose`

**Note:** WSL2 with native Podman provides better performance and resource usage.

## �🤝 Contributing

### 📋 How to Contribute

1. **Fork the project**
2. **Create a branch for your feature**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Test your changes**
   ```bash
   # Validate configurations
   ./validate-config.sh

   # Test with different .env files
   cp .env.example .env.test
   # ... edit .env.test
   podman-compose --env-file .env.test up -d
   ```
4. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
5. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
6. **Open a Pull Request**

### 🔧 Best Practices for Contributions

#### **Adding New Environment Variables**
- Add the variable in `.env.example` with default value
- Document in the "Environment Variables for Parameterization" section
- Include validation in the diagnostic script
- Add practical usage example

#### **Modifying Configurations**
- Always use environment variables instead of hardcoded values
- Maintain compatibility with existing configurations
- Test with different variable values

#### **Documentation**
- Keep README.md updated
- Include practical usage examples
- Document troubleshooting for new features

### 📖 FAQ - Environment Variables

#### **Q: How do I know if my TUNNEL_NAME is unique?**
A: Run the container and check the logs. If "tunnel name already exists" appears, change the name. Use formats like `user-project-dev` or `company-user-$(date +%Y%m%d)`.

#### **Q: Can I use the same TUNNEL_NAME on multiple machines?**
A: No! Each instance needs a unique name. Use suffixes like `-desktop`, `-laptop`, `-server`.

#### **Q: How do I change settings after the container is created?**
A: Edit the `.env`, then recreate the container:
```bash
podman-compose down
podman-compose up -d
```

#### **Q: Are environment variables security sensitive?**
A: The `.env` may contain sensitive information (proxies with credentials). Always add `.env` to `.gitignore` and use `.env.example` for templates.

#### **Q: Can I use operating system variables?**
A: Yes! Example:
```bash
# In .env
TUNNEL_NAME=${USER}-dev-tunnel
TZ=$(timedatectl show --property=Timezone --value)
```

#### **Q: How to use in CI/CD?**
A: Define variables in the pipeline:
```bash
export TUNNEL_NAME="ci-build-${BUILD_NUMBER}"
export TZ="UTC"
podman-compose up -d
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [VS Code](https://code.visualstudio.com/) for the excellent tool
- [Podman](https://podman.io/) for the secure Docker alternative
- Open source community for examples and inspiration

## 📞 Support

- 🐛 [Issues](https://github.com/your-username/vscodetunnelpod/issues)
- 💬 [Discussions](https://github.com/your-username/vscodetunnelpod/discussions)
- 📧 Email: bokomoko+vscodetunnelpod@gmail.com

---

⭐ If this project was useful, consider giving it a star on GitHub!
