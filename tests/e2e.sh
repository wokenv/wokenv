#!/usr/bin/env bash

# End-to-end test: drives a real wp-env through the wokenv CLI.
#
# Usage: tests/e2e.sh
#
# Needs a running Docker daemon and free ports (8025, 8888). Uses the wokenv
# checkout this script lives in. Environment variables:
#   WOKENV_E2E_CORE  wp-env "core" source to test against (default: latest WordPress)

set -euo pipefail

WOKENV="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/wokenv"
WORKDIR=$(mktemp -d)
PROJECT="$WORKDIR/wokenv-e2e"
FAILED=0

pass() { echo "✓ $1"; }
fail() {
    echo "✗ $1"
    FAILED=1
}
check() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then pass "$description"; else fail "$description"; fi
}

# shellcheck disable=SC2329
cleanup() {
    (cd "$PROJECT" 2>/dev/null && "$WOKENV" destroy --yes >/dev/null 2>&1) || true
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

mkdir -p "$PROJECT/includes"
cat >"$PROJECT/wokenv-e2e.php" <<'PHP'
<?php
/**
 * Plugin Name: Wokenv E2E
 */

add_action('init', static function () {
    if (isset($_GET['wokenv-e2e-mail'])) {
        echo wp_mail('e2e@example.com', 'Wokenv E2E', 'It works.') ? 'mail-sent' : 'mail-failed';
        exit;
    }
});
PHP

cd "$PROJECT"

check "init creates wokenv.yml" "$WOKENV" init
check "init detects the plugin" grep -q '^type: plugin$' wokenv.yml
if [ -n "${WOKENV_E2E_CORE:-}" ]; then
    printf '  core: %s\n' "$WOKENV_E2E_CORE" >>wokenv.yml
fi

"$WOKENV" start || fail "start"

check "WordPress answers on port 8888" curl -fsS -o /dev/null http://localhost:8888/
check "the project plugin is active" "$WOKENV" wp plugin is-active wokenv-e2e
cwd=$(cd includes && "$WOKENV" run cli --env-cwd=wp-content/plugins/wokenv-e2e -- pwd 2>/dev/null | tr -d '\r' | tail -n 1)
check "commands work from a subdirectory" test "$cwd" = "/var/www/html/wp-content/plugins/wokenv-e2e"
check "composer is available" "$WOKENV" composer --version
check "node runs in the toolbox" "$WOKENV" node --version

"$WOKENV" run cli --env-cwd=wp-content/plugins/wokenv-e2e -- touch created-in-container >/dev/null 2>&1 || true
check "files created in the container belong to the host user" test -O created-in-container

check "wp_mail() succeeds" bash -c "curl -fsS 'http://localhost:8888/?wokenv-e2e-mail=1' | grep -q mail-sent"
sleep 1
check "Mailpit received the message" bash -c "curl -fsS http://localhost:8025/api/v1/messages | grep -q '\"Subject\":\"Wokenv E2E\"'"

check "status" "$WOKENV" status
check "stop" "$WOKENV" stop
check "WordPress is down after stop" bash -c '! curl -fsS -o /dev/null http://localhost:8888/'
check "start again" "$WOKENV" start
check "WordPress is back" curl -fsS -o /dev/null http://localhost:8888/
check "destroy" "$WOKENV" destroy --yes

files=$(find . -mindepth 1 -maxdepth 1 | sort | tr '\n' ' ')
check "the project only gained wokenv.yml" test "$files" = "./created-in-container ./includes ./wokenv-e2e.php ./wokenv.yml "

exit "$FAILED"
