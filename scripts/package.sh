#!/usr/bin/env bash
# Pack the built standalone server into dist/<name>.tar.gz (+ .sha256).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node
[ -f "$STANDALONE/server.js" ] || die "no build found; run scripts/build.sh first"

OUT="${1:-$ROOT/dist}"
NAME="storyteller-${UPSTREAM_REF:0:8}-macos-arm64"
mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/licenses"

READIUM_V="${READIUM_VERSION:-$(upstream_readium_version)}"
cat > "$STAGE/build-info.json" <<JSON
{
  "upstream_repo": "${UPSTREAM_REPO%.git}",
  "upstream_ref": "$UPSTREAM_REF",
  "upstream_base_tag": "$UPSTREAM_BASE_TAG",
  "readium": "$READIUM_V",
  "node": "$(node -v)",
  "macos_build_host": "$(sw_vers -productVersion)",
  "arch": "$(uname -m)",
  "built_at": "$(date -u +%FT%TZ)",
  "scripts_commit": "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
}
JSON

cp "$UPSTREAM_DIR/LICENSE" "$STAGE/licenses/storyteller-LICENSE"
for f in libraries/ghost-story/LICENSE.md libraries/align/LICENSE.txt libraries/mlx-audio/LICENSE libraries/mlx-audio/LICENSE.md; do
  [ -f "$UPSTREAM_DIR/$f" ] && cp "$UPSTREAM_DIR/$f" "$STAGE/licenses/$(echo "$f" | tr '/' '_')"
done

cat > "$STAGE/NOTICE.md" <<NOTICE
# Notice

This archive is an unofficial macOS build of Storyteller made from the upstream source at
${UPSTREAM_REPO%.git} (commit $UPSTREAM_REF, nearest release tag $UPSTREAM_BASE_TAG).
It is not affiliated with or endorsed by the Storyteller project.

Storyteller is MIT licensed. The build bundles third-party packages under their own licenses,
including packages that are GPL-3.0 (for example \`ghost-story\`). Their license files are in
\`licenses/\`, and the complete corresponding source is the upstream commit above. The build
scripts are at https://github.com/DroidThug/storyteller-macos.
NOTICE

tar -czf "$OUT/$NAME.tar.gz" -C "$WEB_DIR/.next" standalone -C "$STAGE" NOTICE.md build-info.json licenses
(cd "$OUT" && shasum -a 256 "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
log "Packed $OUT/$NAME.tar.gz ($(du -h "$OUT/$NAME.tar.gz" | cut -f1))"
