#!/usr/bin/env bash
# Start the server. Config via env: STORYTELLER_DATA_DIR (default ./data), PORT (8001),
# HOSTNAME (127.0.0.1), READIUM_PORT (9000).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node

DATA="${STORYTELLER_DATA_DIR:-$ROOT/data}"
# Refuse to silently create a data dir on the internal disk when an external volume is missing.
case "$DATA" in
  /Volumes/*)
    vol="/Volumes/$(printf '%s' "${DATA#/Volumes/}" | cut -d/ -f1)"
    [ -d "$vol" ] || die "volume not mounted: $vol"
    ;;
esac
mkdir -p "$DATA"

if [ -z "${STORYTELLER_SECRET_KEY:-}" ] && [ -z "${STORYTELLER_SECRET_KEY_FILE:-}" ]; then
  export STORYTELLER_SECRET_KEY_FILE="$DATA/.secret"
  if [ ! -f "$STORYTELLER_SECRET_KEY_FILE" ]; then
    (umask 077; openssl rand -hex 32 > "$STORYTELLER_SECRET_KEY_FILE")
  fi
fi

[ -f "$STANDALONE/server.js" ] || die "no build found; run scripts/build.sh"
cd "$STANDALONE"

# keep the MLX addon + metallib next to the app even if build.sh was not rerun
mkdir -p prebuilds/darwin-arm64
cp -n "$UPSTREAM_DIR"/libraries/mlx-audio/prebuilds/darwin-arm64/* prebuilds/darwin-arm64/ 2>/dev/null || true

export STORYTELLER_DATA_DIR="$DATA"
export PORT="${PORT:-8001}"
export HOSTNAME="${HOSTNAME_BIND:-127.0.0.1}"
export READIUM_PORT="${READIUM_PORT:-9000}"
export STORYTELLER_WORKER=worker.mjs
export STORYTELLER_FILE_WRITE_WORKER=fileWriteWorker.mjs
export ERROR_ALIGN_NATIVE_BINDING="$PWD/work-dist/@storyteller-platform/align/"
export NODE_ENV=production
exec node --enable-source-maps server.js
