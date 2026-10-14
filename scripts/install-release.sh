#!/usr/bin/env bash
# Install a prebuilt release instead of building. Usage: install-release.sh [tag]   (default: latest)
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

REPO="${RELEASE_REPO:-DroidThug/storyteller-macos}"
TAG="${1:-latest}"
[ "$(uname -s)" = Darwin ] && [ "$(uname -m)" = arm64 ] || die "prebuilt releases are macOS arm64 only"

log "Tools"
for f in ffmpeg "node@$NODE_MAJOR"; do
  brew list --formula "$f" >/dev/null 2>&1 || brew install "$f"
done
use_node

if [ "$TAG" = latest ]; then API="https://api.github.com/repos/$REPO/releases/latest"; else API="https://api.github.com/repos/$REPO/releases/tags/$TAG"; fi
log "Release $TAG from $REPO"
META="$(curl -fsS "$API")"
read -r URL SHA_URL < <(printf '%s' "$META" | python3 -I -c '
import json,sys
r=json.load(sys.stdin); a={x["name"]:x["browser_download_url"] for x in r["assets"]}
t=[n for n in a if n.endswith(".tar.gz")][0]
print(a[t], a[t+".sha256"])')

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fL --progress-bar -o "$TMP/release.tar.gz" "$URL"
curl -fsSL -o "$TMP/release.sha256" "$SHA_URL"
want="$(awk '{print $1}' "$TMP/release.sha256")"
got="$(shasum -a 256 "$TMP/release.tar.gz" | awk '{print $1}')"
[ "$want" = "$got" ] || die "checksum mismatch"

log "Unpack to $ROOT/runtime"
mkdir -p "$TMP/x"
tar -xzf "$TMP/release.tar.gz" -C "$TMP/x"
rm -rf "$ROOT/runtime"
mv "$TMP/x" "$ROOT/runtime"

READIUM="${READIUM_VERSION:-$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))["readium"])' "$ROOT/runtime/build-info.json")}"
log "Readium $READIUM"
bash "$ROOT/runtime/standalone/applications/web/install-readium-cli.sh" "$READIUM"

log "Done. Next: scripts/install-models.sh, then scripts/run.sh"
