#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

SCRIPT="$HERE/../check-update.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A fake plugin root with an installed manifest at version 0.2.0.
mkdir -p "$TMP/plugin/.claude-plugin"
printf '{"name":"gigadump","version":"0.2.0"}' > "$TMP/plugin/.claude-plugin/plugin.json"

# A stub `curl` on PATH that returns a manifest with a configurable version.
mkdir -p "$TMP/bin"
make_curl() { # $1 = version the remote reports
  cat > "$TMP/bin/curl" <<STUB
#!/usr/bin/env bash
# ignore all args; emit a plugin.json with the canned version
printf '{"name":"gigadump","version":"$1"}'
STUB
  chmod +x "$TMP/bin/curl"
}

run() { # runs the notifier with isolated env; echoes stdout
  PATH="$TMP/bin:$PATH" \
  CLAUDE_PLUGIN_ROOT="$TMP/plugin" \
  GIGADUMP_CONFIG="$TMP/config.json" \
  GIGADUMP_UPDATE_CACHE="$TMP/cache.json" \
  GIGADUMP_VERSION_URL="http://example.invalid/plugin.json" \
  bash "$SCRIPT"
}

# --- newer version available -> notifies ---
rm -f "$TMP/cache.json" "$TMP/config.json"
make_curl "0.3.0"
out="$(run)"
case "$out" in
  *'"systemMessage"'*'0.3.0'*) assert_eq "0" "0" "notifies when a newer version is available" ;;
  *) assert_eq "notice" "$out" "notifies when a newer version is available" ;;
esac

# --- second run within interval -> throttled (silent), cache exists now ---
out="$(run)"
assert_eq "" "$out" "second run within interval is silent (throttled)"

# --- equal version -> no notice ---
rm -f "$TMP/cache.json"
make_curl "0.2.0"
out="$(run)"
assert_eq "" "$out" "no notice when installed == latest"

# --- remote ahead is older than installed -> no notice ---
rm -f "$TMP/cache.json"
make_curl "0.1.0"
out="$(run)"
assert_eq "" "$out" "no notice when installed is newer than remote"

# --- opt-out via updateNotifications:false -> silent even when behind ---
rm -f "$TMP/cache.json"
printf '{"updateNotifications": false}' > "$TMP/config.json"
make_curl "0.9.0"
out="$(run)"
assert_eq "" "$out" "silent when updateNotifications is false"

finish
