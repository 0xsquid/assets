# Shared helpers for the update-tokens smoke test suite.
# Source from a test file: source "$(dirname "$0")/../lib.sh"
#
# Tests are expected to be run from the repo root (the orchestrator cds there
# before invoking them; if you run a test directly, cd to the repo root first
# or paths will break).

# WETH on Ethereum — reliable regression target (always in the Squid response).
# Override INTEGRATION_TARGET in your environment to test with a different token.
INTEGRATION_TARGET="${INTEGRATION_TARGET:-images/migration/webp/1_0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2.webp}"
INTEGRATION_BASE=$(basename "$INTEGRATION_TARGET" .webp 2>/dev/null || true)

# Exit 77 with a one-line reason if the integration prerequisites are missing.
# Tests that hit the network call this before doing any work.
require_integration_prereqs() {
  if [ ! -f "$INTEGRATION_TARGET" ]; then
    echo "target file not present locally: $INTEGRATION_TARGET"
    exit 77
  fi
  if [ ! -f .env ] && [ -z "${SQUID_API_URL:-}" ]; then
    echo "no .env file and SQUID_API_URL not set"
    exit 77
  fi
}

# Portable timeout — pure bash, no GNU coreutils dependency.
# Usage: run_with_timeout <seconds> <command...>
# Exits with the command's exit code, or 137 if killed by SIGKILL on timeout.
run_with_timeout() {
  local seconds=$1
  shift
  (
    "$@" &
    local cmd_pid=$!
    ( sleep "$seconds"; kill -KILL "$cmd_pid" 2>/dev/null ) &
    local killer_pid=$!
    wait "$cmd_pid" 2>/dev/null
    local exit_code=$?
    kill -KILL "$killer_pid" 2>/dev/null
    wait "$killer_pid" 2>/dev/null
    exit "$exit_code"
  )
}

# Snapshot the files the pipeline tests will modify, into /tmp.
pipeline_setup() {
  cp "$INTEGRATION_TARGET" /tmp/smoke-pre-webp
  cp scripts/update-tokens/colors.json /tmp/smoke-pre-colors.json
  cp scripts/update-tokens/url_fetch_errors.json /tmp/smoke-pre-url-errors.json \
    2>/dev/null || : >/tmp/smoke-pre-url-errors.json
}

# Restore the snapshot. Call via trap to ensure cleanup on any exit.
pipeline_restore() {
  cp /tmp/smoke-pre-webp "$INTEGRATION_TARGET" 2>/dev/null || true
  cp /tmp/smoke-pre-colors.json scripts/update-tokens/colors.json
  [ -s /tmp/smoke-pre-url-errors.json ] && \
    cp /tmp/smoke-pre-url-errors.json scripts/update-tokens/url_fetch_errors.json
  rm -f /tmp/smoke-pre-webp /tmp/smoke-pre-colors.json \
        /tmp/smoke-pre-url-errors.json /tmp/smoke-update.log
}

# Mutate colors.json to remove the entry for INTEGRATION_BASE.
delete_color_entry() {
  node -e "
    const fs = require('fs');
    const path = 'scripts/update-tokens/colors.json';
    const c = JSON.parse(fs.readFileSync(path));
    delete c.tokens['$INTEGRATION_BASE'];
    fs.writeFileSync(path, JSON.stringify(c, null, 2));
  "
}

# Exit 0 if colors.json has a non-empty bgColor for INTEGRATION_BASE, else 1.
color_entry_present() {
  node -e "
    const fs = require('fs');
    const c = JSON.parse(fs.readFileSync('scripts/update-tokens/colors.json'));
    const e = c.tokens['$INTEGRATION_BASE'];
    process.exit(e && e.bgColor ? 0 : 1);
  "
}
