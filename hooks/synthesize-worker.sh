#!/usr/bin/env bash
# gigadump session synthesis — background worker. Best-effort; never fatal.
# Always exits 0. Guards nested `claude` against re-triggering the hook.
set -uo pipefail

: "${GIGADUMP_LOG:=$HOME/.config/gigadump/synthesize.log}"
: "${GIGADUMP_MAX_CHARS:=60000}"
export GIGADUMP_HOOK_ACTIVE=1

log() {
  mkdir -p "$(dirname "$GIGADUMP_LOG")" 2>/dev/null || true
  printf '%s [worker] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo now)" "$*" >>"$GIGADUMP_LOG" 2>/dev/null || true
}

today() { date -u +%Y-%m-%d 2>/dev/null || echo 0000-00-00; }

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-50
}

# Extract salient transcript content: assistant prose + concise tool markers.
extract_transcript() {
  jq -rs '
    [ .[] | select(.type=="assistant") | .message.content[]? |
      if .type=="text" then .text
      elif .type=="tool_use" then "[tool:" + .name + "] " + ((.input.command // .input.file_path // "") | tostring)
      else empty end
    ] | join("\n")
  ' "$TRANSCRIPT" 2>/dev/null | tail -c "$GIGADUMP_MAX_CHARS"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  : # main added in Task 6
fi
