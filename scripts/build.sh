#!/usr/bin/env bash
# yarn install + production build + assemble the standalone server for macOS.
# BUILD_NICE=19 runs it at low priority. --assemble-only skips install/build.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node
[ -d "$UPSTREAM_DIR/.git" ] || die "run scripts/setup.sh first"

run() { if [ -n "${BUILD_NICE:-}" ]; then nice -n "$BUILD_NICE" "$@"; else "$@"; fi; }

assemble() {
  log "Assemble standalone server"
  local S="$STANDALONE"
  [ -f "$S/server.js" ] || die "no standalone build at $S"
  mkdir -p "$S/.next/static" "$S/public" "$S/scripts" \
    "$S/work-dist/@storyteller-platform/align/prebuilds" "$S/prebuilds/darwin-arm64"
  cp -R "$WEB_DIR/.next/static/." "$S/.next/static/"
  cp -R "$WEB_DIR/public/." "$S/public/"
  cp "$UPSTREAM_DIR"/docker-scripts/* "$S/scripts/"
  local d
  for d in work-dist file-write-dist migrations; do
    mkdir -p "$S/$d"
    cp -R "$WEB_DIR/$d/." "$S/$d/"
  done
  # upstream's Dockerfile only copies the linux align prebuilds
  cp -R "$UPSTREAM_DIR/libraries/align/prebuilds/darwin-arm64" \
    "$S/work-dist/@storyteller-platform/align/prebuilds/"
  cp "$UPSTREAM_DIR"/node_modules/@echogarden/icu-segmentation-wasm/wasm/*.wasm "$S/work-dist/"
  # ...and never copies the MLX addon or mlx.metallib (no MLX on linux), so the
  # app fails at "MLX Metal shader library not found" without this
  cp "$UPSTREAM_DIR"/libraries/mlx-audio/prebuilds/darwin-arm64/* "$S/prebuilds/darwin-arm64/"
}

if [ "${1:-}" != "--assemble-only" ]; then
  cd "$UPSTREAM_DIR"
  log "yarn install"
  ONNXRUNTIME_NODE_INSTALL=skip run yarn install --inline-builds
  log "build (this takes a while)"
  NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 \
    run yarn workspaces foreach -Rpt --from @storyteller-platform/web run build
fi
assemble
log "Done. Next: scripts/install-models.sh, then scripts/run.sh"
