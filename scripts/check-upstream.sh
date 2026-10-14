#!/usr/bin/env bash
# Compare our pin with upstream. Writes outputs for GitHub Actions when GITHUB_OUTPUT is set.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

latest_tag="$(curl -fsS "$UPSTREAM_API/repository/tags?per_page=30&search=%5Eweb-v" |
  python3 -I -c 'import json,sys
for t in json.load(sys.stdin):
    if t["name"].startswith("web-v"):
        print(t["name"]); break')"
main_head="$(curl -fsS "$UPSTREAM_API/repository/branches/main" |
  python3 -I -c 'import json,sys; print(json.load(sys.stdin)["commit"]["id"])')"

# readium version upstream ships at main vs at our pin
up_readium="$(curl -fsS "https://gitlab.com/storyteller-platform/storyteller/-/raw/main/Dockerfile" |
  grep -oE 'readium/readium:[0-9][0-9.]*' | head -1 | cut -d: -f2 || true)"
pin_readium="${READIUM_VERSION:-$(upstream_readium_version)}"

changed=false
[ -n "$latest_tag" ] && [ "$latest_tag" != "$UPSTREAM_BASE_TAG" ] && changed=true

echo "pinned ref:      $UPSTREAM_REF"
echo "pinned base tag: $UPSTREAM_BASE_TAG"
echo "latest web tag:  ${latest_tag:-?}"
echo "upstream main:   $main_head"
echo "readium (ours):  $pin_readium"
echo "readium (main):  ${up_readium:-?}"
echo "new release:     $changed"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "changed=$changed"
    echo "latest_tag=$latest_tag"
    echo "main_head=$main_head"
    echo "readium_upstream=$up_readium"
  } >> "$GITHUB_OUTPUT"
fi
