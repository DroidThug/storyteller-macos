#!/usr/bin/env bash
# Shared helpers. Source this, do not execute it.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
# shellcheck disable=SC1091
. "$ROOT/config.env"
set +a

UPSTREAM_DIR="${UPSTREAM_DIR:-$ROOT/upstream}"
TOOLS_BIN="$ROOT/.tools/bin"
WEB_DIR="$UPSTREAM_DIR/applications/web"
# shellcheck disable=SC2034 # used by the scripts that source this file
STANDALONE="$WEB_DIR/.next/standalone/applications/web"

log() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

node_major() { node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo none; }

# Make sure the right Node is first on PATH (Homebrew's node@N is keg-only).
use_node() {
  export PATH="$TOOLS_BIN:$HOME/.local/bin:$PATH"
  if [ "$(node_major)" != "$NODE_MAJOR" ]; then
    local p
    for p in "/opt/homebrew/opt/node@$NODE_MAJOR/bin" "/usr/local/opt/node@$NODE_MAJOR/bin"; do
      [ -d "$p" ] && export PATH="$p:$PATH"
    done
  fi
  [ "$(node_major)" = "$NODE_MAJOR" ] || die "need Node $NODE_MAJOR (found $(node_major)); run scripts/setup.sh"
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
}

ghost_story() { node "$UPSTREAM_DIR/libraries/ghost-story/dist/cli/bin.js" "$@"; }

# Readium version upstream ships in its Dockerfile (the production path). Falls back to 0.9.1.
upstream_readium_version() {
  local v=""
  [ -f "$UPSTREAM_DIR/Dockerfile" ] &&
    v="$(grep -oE 'readium/readium:[0-9][0-9.]*' "$UPSTREAM_DIR/Dockerfile" | head -1 | cut -d: -f2)"
  printf '%s' "${v:-0.9.1}"
}
