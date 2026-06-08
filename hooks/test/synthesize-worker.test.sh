#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

# Source worker without running main (no args needed because main is guarded).
source "$HERE/../synthesize-worker.sh"

# slugify
assert_eq "hello-world" "$(slugify 'Hello, World!')" "slugify lowercases and dashes"
assert_eq "a-b-c" "$(slugify '  a   b   c  ')" "slugify collapses whitespace"

# extract_transcript pulls assistant text + tool markers.
FX="$HERE/fixtures"
out="$(TRANSCRIPT="$FX/edits.jsonl" extract_transcript)"
case "$out" in
  *"Editing"*) assert_eq "0" "0" "extract includes assistant text" ;;
  *) assert_eq "1" "0" "extract includes assistant text" ;;
esac
case "$out" in
  *"[tool:Write]"*) assert_eq "0" "0" "extract includes tool marker" ;;
  *) assert_eq "1" "0" "extract includes tool marker" ;;
esac

finish
