#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

# Wokenv Installer
# https://github.com/wokenv/wokenv

WOKENV_DIR="${HOME}/.wokenv"
REPO_URL="https://github.com/wokenv/wokenv"
BRANCH="${WOKENV_BRANCH:-main}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Wokenv Installation Script           ║${NC}"
echo -e "${GREEN}║   WordPress Development Environment    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &>/dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    echo "Please install git first: https://git-scm.com/downloads"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker daemon is running
if ! docker ps &>/dev/null; then
    echo -e "${RED}Error: Docker daemon is not running.${NC}"
    echo "Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available (V2 integrated or V1 standalone)
if docker compose version &>/dev/null; then
    # Docker Compose V2 (integrated in Docker)
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    # Docker Compose V1 (standalone)
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}Error: Docker Compose is not available.${NC}"
    echo "Docker Compose V2 is included in Docker Desktop and recent Docker Engine versions."
    echo "See: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Using: $COMPOSE_CMD${NC}"

echo -e "${YELLOW}Installing Wokenv to: ${WOKENV_DIR}${NC}"
echo ""

# Create directory if it doesn't exist
if [ -d "$WOKENV_DIR" ]; then
    echo -e "${YELLOW}Wokenv directory already exists.${NC}"
    read -p "Do you want to update it? [y/N] " -n 1 -r </dev/tty
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "Updating Wokenv..."
    cd "$WOKENV_DIR"
    git pull origin "$BRANCH"
else
    echo "Cloning Wokenv repository..."
    git clone -b "$BRANCH" "$REPO_URL" "$WOKENV_DIR"
fi

# Make scripts executable
chmod +x "$WOKENV_DIR/bin/wokenv"
chmod +x "$WOKENV_DIR/install.sh"

# Install wokenv binary
echo ""
echo "Installing 'wokenv' command..."

# Try ~/.local/bin first (user install - no sudo needed)
if [ -d "$HOME/.local/bin" ]; then
    ln -sf "$WOKENV_DIR/bin/wokenv" "$HOME/.local/bin/wokenv"
    echo -e "${GREEN}✓ Installed 'wokenv' to ~/.local/bin${NC}"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "${YELLOW}⚠️  Add ~/.local/bin to your PATH:${NC}"
        echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "   source ~/.bashrc"
    fi
# Try /usr/local/bin as fallback (requires sudo)
elif [ -w "/usr/local/bin" ] || sudo -n true 2>/dev/null; then
    read -p "Install 'wokenv' to /usr/local/bin (requires sudo)? [y/N] " -n 1 -r </dev/tty
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ln -sf "$WOKENV_DIR/bin/wokenv" /usr/local/bin/wokenv
        echo -e "${GREEN}✓ Installed 'wokenv' to /usr/local/bin${NC}"
    else
        echo -e "${YELLOW}⚠️  'wokenv' command not installed${NC}"
        echo "   You can manually create ~/.local/bin and add it to PATH"
    fi
else
    echo -e "${YELLOW}⚠️  Could not install 'wokenv' command automatically${NC}"
    echo "   Create ~/.local/bin or run with sudo to install to /usr/local/bin"
fi

# Optional Docker image pull
#echo ""
#read -p "Pull default Docker image (frugan/wokenv:latest) now? [Y/n] " -n 1 -r </dev/tty
#echo
#if [[ ! $REPLY =~ ^[Nn]$ ]]; then
#    echo ""
#    echo "Pulling Wokenv Docker image..."
#    docker pull frugan/wokenv:latest || {
#        echo -e "${YELLOW}Warning: Could not pull Docker image. Will be pulled on first use.${NC}"
#    }
#else
#    echo "Skipped Docker image pull. Image will be pulled on first use."
#fi

# Optional dependencies
echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}  Optional Dependencies                 ${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""
echo "Wokenv can use optional dependencies for robust YAML parsing:"
echo ""
echo -e "1. ${GREEN}yq${NC} - Fast YAML processor (recommended)"
echo "   • Best performance and reliability"
echo "   • Handles complex YAML files"
echo ""
echo -e "2. ${GREEN}PyYAML${NC} - Python YAML library (alternative)"
echo "   • Good reliability"
echo "   • Requires Python 3"
echo ""
echo "Without these, Wokenv uses basic grep/sed parsing."
echo "This works for standard configs but is fragile with:"
echo "  • Comments inline"
echo "  • Extra spaces"
echo "  • Quotes"
echo "  • Complex YAML"
echo ""

# Function to install yq
install_yq() {
    echo -e "${BLUE}Installing yq...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &>/dev/null; then
            echo "Using Homebrew..."
            if brew install yq; then
                echo -e "${GREEN}✓ yq installed via Homebrew${NC}"
                return 0
            fi
        else
            echo -e "${YELLOW}Homebrew not found.${NC}"
            echo "Install manually from: https://github.com/mikefarah/yq#install"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - install binary directly
        local YQ_VERSION="v4.40.5"
        local ARCH
        ARCH=$(uname -m)
        local YQ_BINARY

        case $ARCH in
        x86_64)
            YQ_BINARY="yq_linux_amd64"
            ;;
        aarch64 | arm64)
            YQ_BINARY="yq_linux_arm64"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $ARCH${NC}"
            echo "Install manually from: https://github.com/mikefarah/yq#install"
            return 1
            ;;
        esac

        echo "Downloading yq ${YQ_VERSION} for ${ARCH}..."

        if ! wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -O /tmp/yq; then
            echo -e "${RED}Failed to download yq${NC}"
            return 1
        fi

        chmod +x /tmp/yq

        # Try ~/.local/bin first
        if mkdir -p "$HOME/.local/bin" 2>/dev/null && mv /tmp/yq "$HOME/.local/bin/yq"; then
            echo -e "${GREEN}✓ yq installed to ~/.local/bin/yq${NC}"

            # Check if in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo -e "${YELLOW}⚠️  Add ~/.local/bin to your PATH (if not already done above)${NC}"
            fi
            return 0
        # Try /usr/local/bin with sudo
        elif sudo -n true 2>/dev/null && sudo mv /tmp/yq /usr/local/bin/yq; then
            echo -e "${GREEN}✓ yq installed to /usr/local/bin/yq${NC}"
            return 0
        else
            echo -e "${YELLOW}Could not move yq to PATH.${NC}"
            echo "Please manually move /tmp/yq to a directory in your PATH"
            return 1
        fi
    else
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        echo "Install manually from: https://github.com/mikefarah/yq#install"
        return 1
    fi
}

# Function to install PyYAML
install_pyyaml() {
    echo -e "${BLUE}Installing PyYAML...${NC}"

    # Check Python
    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}Python 3 is not installed. Skipping PyYAML.${NC}"
        return 1
    fi

    local python_version
    python_version=$(python3 --version | sed 's/Python //')
    echo "Python version: $python_version"

    # Try pip install
    if command -v pip3 &>/dev/null; then
        echo "Installing PyYAML via pip..."
        if pip3 install --user pyyaml; then
            echo -e "${GREEN}✓ PyYAML installed${NC}"
            return 0
        else
            echo -e "${YELLOW}Failed to install PyYAML via pip${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}pip3 not found. Skipping PyYAML.${NC}"
        return 1
    fi
}

# Check what's already installed
HAS_YQ=false
HAS_PYYAML=false

if command -v yq &>/dev/null; then
    HAS_YQ=true
    echo -e "${GREEN}✓ yq is already installed${NC}"
fi

if command -v python3 &>/dev/null && python3 -c "import yaml" 2>/dev/null; then
    HAS_PYYAML=true
    echo -e "${GREEN}✓ PyYAML is already installed${NC}"
fi

if [ "$HAS_YQ" = false ] && [ "$HAS_PYYAML" = false ]; then
    echo ""
    echo "Would you like to install optional dependencies now?"
    echo ""
    echo "  1) Install yq only (recommended)"
    echo "  2) Install PyYAML only"
    echo "  3) Install both"
    echo "  4) Skip (can install later with: wokenv self-install-deps)"
    echo ""
    read -p "Enter choice [1-4]: " -r dep_choice </dev/tty

    case $dep_choice in
    1)
        install_yq
        ;;
    2)
        install_pyyaml
        ;;
    3)
        install_yq
        install_pyyaml
        ;;
    4)
        echo "Skipping optional dependencies."
        echo -e "You can install them later with: ${CYAN}wokenv self-install-deps${NC}"
        ;;
    *)
        echo "Invalid choice. Skipping optional dependencies."
        ;;
    esac
elif [ "$HAS_YQ" = true ]; then
    echo ""
    echo -e "${GREEN}You already have yq installed - the best option!${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Wokenv has been installed to: $WOKENV_DIR"
echo ""
echo "What's included:"
echo "  • Centralized docker-compose.yml with Mailpit and phpMyAdmin"
echo "  • Wokenv CLI for easy project management"
echo "  • Templates for plugins, themes, and core development"
echo "  • Automatic version compatibility checking"
echo "  • 3-level YAML parsing with fallbacks"
echo ""
echo "To get started with a new WordPress project:"
echo ""
echo "  1. Navigate to your project directory:"
echo "     cd /path/to/your-project"
echo ""
echo "  2. Initialize the project:"
echo -e "     ${CYAN}wokenv init${NC}"
echo ""
echo "  3. Follow the guided setup, then install dependencies (optional):"
echo -e "     ${CYAN}wokenv install${NC}"
echo ""
echo "  4. Start WordPress:"
echo -e "     ${CYAN}wokenv start${NC}"
echo ""
echo "  5. Access your environment:"
echo "     WordPress:    http://localhost:8888"
echo "     Admin:        http://localhost:8888/wp-admin (admin/password)"
echo "     Mailpit:      http://localhost:8025"
echo "     phpMyAdmin:   http://localhost:9000"
echo ""
echo "Useful commands:"
echo -e "  • ${CYAN}wokenv help${NC}              - Show all commands"
echo -e "  • ${CYAN}wokenv self-check${NC}        - Verify installation"
echo -e "  • ${CYAN}wokenv self-install-deps${NC} - Install optional dependencies"
echo -e "  • ${CYAN}wokenv self-update${NC}       - Update to latest version"
echo ""
echo "Documentation: ${REPO_URL}"
echo ""
