#!/usr/bin/env bash
# Unpack a release archive somewhere else and boot it, to prove it is relocatable and self-contained.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node
ARCHIVE="${1:?usage: verify-release.sh <archive.tar.gz>}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
tar -xzf "$ARCHIVE" -C "$TMP"
[ -f "$TMP/NOTICE.md" ] && [ -f "$TMP/build-info.json" ] && [ -d "$TMP/licenses" ] || die "archive is missing NOTICE/build-info/licenses"
# no upstream checkout available: only what is in the archive
export UPSTREAM_DIR="$TMP/nonexistent-upstream"
export RUNTIME_DIR="$TMP/standalone/applications/web"
"$ROOT/scripts/smoke.sh"
