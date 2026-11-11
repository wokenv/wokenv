#!/usr/bin/env bash

# Wokenv Installer
# https://github.com/wokenv/wokenv
#
# Usage: curl -fsSL https://raw.githubusercontent.com/wokenv/wokenv/main/install.sh | bash
#
# Environment variables:
#   WOKENV_DIR      Installation directory (default: ~/.wokenv)
#   WOKENV_BRANCH   Branch or tag to install (default: main)
#   WOKENV_BIN_DIR  Where to link the wokenv command (default: ~/.local/bin)

set -euo pipefail

WOKENV_DIR="${WOKENV_DIR:-$HOME/.wokenv}"
BIN_DIR="${WOKENV_BIN_DIR:-$HOME/.local/bin}"
REPO_URL="https://github.com/wokenv/wokenv.git"
BRANCH="${WOKENV_BRANCH:-main}"
IMAGE="frugan/wokenv:latest"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
    RED="" GREEN="" YELLOW="" CYAN="" NC=""
fi

fail() {
    echo "${RED}Error:${NC} $*" >&2
    exit 1
}

echo "${GREEN}Wokenv${NC} - wp-env without Node.js on your machine"
echo ""

command -v git >/dev/null 2>&1 || fail "git is not installed. See https://git-scm.com/downloads"
command -v docker >/dev/null 2>&1 || fail "Docker is not installed. See https://docs.docker.com/get-docker/"
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is required (the 'docker compose' plugin). See https://docs.docker.com/compose/install/"

if [ -d "$WOKENV_DIR/.git" ]; then
    echo "Updating Wokenv in $WOKENV_DIR..."
    git -C "$WOKENV_DIR" fetch --quiet --tags origin "$BRANCH"
    git -C "$WOKENV_DIR" checkout --quiet "$BRANCH"
    # A tag has no upstream to pull from.
    git -C "$WOKENV_DIR" pull --quiet --ff-only origin "$BRANCH" 2>/dev/null || true
elif [ -e "$WOKENV_DIR" ]; then
    fail "$WOKENV_DIR exists but is not a Wokenv checkout. Move it away or set WOKENV_DIR."
else
    echo "Installing Wokenv in $WOKENV_DIR..."
    git clone --quiet --branch "$BRANCH" "$REPO_URL" "$WOKENV_DIR"
fi

mkdir -p "$BIN_DIR"
ln -sf "$WOKENV_DIR/bin/wokenv" "$BIN_DIR/wokenv"

if docker info >/dev/null 2>&1; then
    echo "Pulling $IMAGE..."
    docker pull --quiet "$IMAGE" >/dev/null || echo "${YELLOW}!${NC} Could not pull $IMAGE now: wokenv will retry on first use."
else
    echo "${YELLOW}!${NC} Docker is not running: the image will be pulled on first use."
fi

echo ""
echo "${GREEN}✓${NC} Wokenv $(tr -d '[:space:]' <"$WOKENV_DIR/VERSION") installed"

case ":$PATH:" in
*":$BIN_DIR:"*) ;;
*)
    echo ""
    echo "${YELLOW}!${NC} $BIN_DIR is not in your PATH. Add this line to your shell profile:"
    echo "    export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo ""
echo "Get started:"
echo "  ${CYAN}cd your-plugin-or-theme${NC}"
echo "  ${CYAN}wokenv init${NC}"
echo "  ${CYAN}wokenv start${NC}"
