#!/usr/bin/env bash
# Tools + source checkout + the few LFS files a native macOS build needs.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ "$(uname -s)" = Darwin ] || die "macOS only"
[ "$(uname -m)" = arm64 ] || log "warning: not Apple Silicon; MLX/CoreML paths will not work"

log "Tools"
if command -v brew >/dev/null 2>&1 && [ -z "${GITHUB_ACTIONS:-}" ]; then
  for f in git-lfs ffmpeg "node@$NODE_MAJOR"; do
    brew list --formula "$f" >/dev/null 2>&1 || brew install "$f"
  done
else
  command -v git-lfs >/dev/null || die "git-lfs missing"
  command -v ffmpeg >/dev/null || die "ffmpeg missing"
fi
use_node
if ! command -v corepack >/dev/null 2>&1; then
  npm install -g corepack --prefix "$ROOT/.tools"
fi
mkdir -p "$TOOLS_BIN"
corepack enable --install-directory "$TOOLS_BIN"

log "Source @ ${UPSTREAM_REF:0:8}"
mkdir -p "$UPSTREAM_DIR"
cd "$UPSTREAM_DIR"
if [ ! -d .git ]; then
  git init -q
  git remote add origin "$UPSTREAM_REPO"
fi
git lfs install --local --skip-smudge >/dev/null
if [ "$(git rev-parse HEAD 2>/dev/null || true)" != "$UPSTREAM_REF" ]; then
  GIT_LFS_SKIP_SMUDGE=1 git fetch --depth 1 origin "$UPSTREAM_REF"
  GIT_LFS_SKIP_SMUDGE=1 git checkout -q --detach FETCH_HEAD
fi

log "LFS (darwin-arm64 prebuilds + epub vendors${EXTRA_LFS_INCLUDE:+ + $EXTRA_LFS_INCLUDE})"
INCLUDE="libraries/align/prebuilds/darwin-arm64/**,libraries/mlx-audio/prebuilds/**,libraries/epub/vendors/**"
[ -n "${EXTRA_LFS_INCLUDE:-}" ] && INCLUDE="$INCLUDE,$EXTRA_LFS_INCLUDE"
git lfs pull --include="$INCLUDE"

READIUM="${READIUM_VERSION:-$(upstream_readium_version)}"
log "Readium $READIUM (${READIUM_VERSION:+override}${READIUM_VERSION:-from upstream Dockerfile})"
bash applications/web/install-readium-cli.sh "$READIUM"

log "Done. Next: scripts/build.sh"
