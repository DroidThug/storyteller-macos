#!/usr/bin/env bash
# Run upstream's test suites. TEST_TARGETS overrides the list (names after "test:").
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node
cd "$UPSTREAM_DIR" || exit 1
TARGETS="${TEST_TARGETS:-epub epubcfi fs mapping media-types opds uri-fragment align audiobook ghost-story web}"
failed=()
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
{ echo "### Upstream tests @ ${UPSTREAM_REF:0:8}"; echo; echo "| suite | result |"; echo "|---|---|"; } >> "$summary"
for t in $TARGETS; do
  log "test:$t"
  if yarn "test:$t"; then
    echo "| $t | pass |" >> "$summary"
  else
    echo "| $t | FAIL |" >> "$summary"
    failed+=("$t")
  fi
done
if [ "${#failed[@]}" -gt 0 ]; then echo "failed: ${failed[*]}"; exit 1; fi
