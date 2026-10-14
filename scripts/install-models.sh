#!/usr/bin/env bash
# Transcription/alignment models. SKIP_WHISPER=1 or SKIP_CTC=1 to skip one.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
use_node

if [ -z "${SKIP_WHISPER:-}" ]; then
  log "whisper.cpp ($WHISPER_VARIANT) + $WHISPER_MODEL"
  ghost_story install binary "$WHISPER_VARIANT"
  ghost_story install model "$WHISPER_MODEL"
fi
if [ -z "${SKIP_CTC:-}" ]; then
  log "CTC model quartznet15x5/$CTC_LANGUAGE (MLX)"
  ghost_story install ctc-model quartznet15x5 --device mlx --language "$CTC_LANGUAGE"
fi
