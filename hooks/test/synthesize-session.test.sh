#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

# Source the script under test WITHOUT running main.
source "$HERE/../synthesize-session.sh"

# Reentrancy: guard returns true only when env var set.
( unset GIGADUMP_HOOK_ACTIVE; is_reentrant ); assert_eq "1" "$?" "is_reentrant false when unset"
( export GIGADUMP_HOOK_ACTIVE=1; is_reentrant ); assert_eq "0" "$?" "is_reentrant true when set"

finish
