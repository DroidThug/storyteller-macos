#!/usr/bin/env bash
# Boot the built server on spare ports with a throwaway data dir and check it is healthy.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

APP_PORT="${SMOKE_PORT:-18001}"
READIUM_PORT_SMOKE="${SMOKE_READIUM_PORT:-19000}"
TMP="$(mktemp -d)"
LOG="$TMP/server.log"
PID=""

cleanup() {
  [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
  pkill -f "readium serve -p $READIUM_PORT_SMOKE" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

STORYTELLER_DATA_DIR="$TMP/data" PORT="$APP_PORT" READIUM_PORT="$READIUM_PORT_SMOKE" \
  "$ROOT/scripts/run.sh" >"$LOG" 2>&1 &
PID=$!

code=000
for _ in $(seq 1 90); do
  kill -0 "$PID" 2>/dev/null || { echo "server exited early"; tail -30 "$LOG"; exit 1; }
  code="$(curl -s -o /dev/null -m 3 -w '%{http_code}' "http://127.0.0.1:$APP_PORT/login" || true)"
  case "$code" in 200|307) break ;; esac
  sleep 2
done
case "$code" in 200|307) ;; *) echo "FAIL: /login returned $code"; tail -30 "$LOG"; exit 1 ;; esac

fail=0
if command -v sqlite3 >/dev/null 2>&1; then
  n="$(sqlite3 "$TMP/data/storyteller.db" 'select count(*) from migration' 2>/dev/null || echo 0)"
  if [ "${n:-0}" -gt 0 ]; then echo "ok: $n migrations applied"; else echo "FAIL: no migrations applied"; fail=1; fi
fi
r="$(curl -s -o /dev/null -m 3 -w '%{http_code}' "http://127.0.0.1:$READIUM_PORT_SMOKE/" || true)"
# readium answers 404 on its root path when it is up
if [ "$r" = 404 ]; then echo "ok: readium is up"; else echo "FAIL: readium on $READIUM_PORT_SMOKE returned $r"; fail=1; fi
if grep -q 'Invalid environment variables' "$LOG"; then echo "FAIL: env validation error"; fail=1; fi

if [ "$fail" = 0 ]; then
  echo "SMOKE PASS (/login=$code)"
else
  tail -30 "$LOG"
  exit 1
fi
