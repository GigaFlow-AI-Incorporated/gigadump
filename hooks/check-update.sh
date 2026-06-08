#!/usr/bin/env bash
# gigadump update notifier — SessionStart hook. Best-effort; ALWAYS exits 0.
# At most once per interval (default 24h) it fetches the latest published version
# from the repo's main branch and, if the installed version is behind, prints a
# one-line systemMessage telling the user how to update. Silenced by
# "updateNotifications": false in the gigadump config.
set -uo pipefail

: "${GIGADUMP_CONFIG:=$HOME/.config/gigadump/config.json}"
: "${GIGADUMP_UPDATE_CACHE:=$HOME/.config/gigadump/update-check.json}"
: "${GIGADUMP_VERSION_URL:=https://raw.githubusercontent.com/GigaFlow-AI-Incorporated/gigadump/main/.claude-plugin/plugin.json}"
: "${GIGADUMP_CHECK_INTERVAL:=86400}"

command -v jq >/dev/null 2>&1 || exit 0

# Opt-out: updateNotifications:false silences the notice. (Compare the raw value;
# jq's `// true` would wrongly treat a literal false as "absent" and default on.)
if [[ -f "$GIGADUMP_CONFIG" ]]; then
  [[ "$(jq -r '.updateNotifications' "$GIGADUMP_CONFIG" 2>/dev/null)" == "false" ]] && exit 0
fi

# Installed version from this plugin's own manifest.
manifest=""
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -f "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" ]]; then
  manifest="${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"
else
  manifest="$(find "$HOME/.claude/plugins" -path '*gigadump*/.claude-plugin/plugin.json' 2>/dev/null | head -1)"
fi
[[ -n "$manifest" && -f "$manifest" ]] || exit 0
installed="$(jq -r '.version // empty' "$manifest" 2>/dev/null)"
[[ -n "$installed" ]] || exit 0

now="$(date +%s 2>/dev/null || echo 0)"

# Throttle: if we already checked within the interval, stay silent (no network,
# no repeated notice the same day).
last_check=0; latest=""
if [[ -f "$GIGADUMP_UPDATE_CACHE" ]]; then
  last_check="$(jq -r '.last_check // 0' "$GIGADUMP_UPDATE_CACHE" 2>/dev/null || echo 0)"
  latest="$(jq -r '.latest // empty' "$GIGADUMP_UPDATE_CACHE" 2>/dev/null || echo "")"
fi
if [[ "$now" -gt 0 && "$last_check" -gt 0 ]] && (( now - last_check < GIGADUMP_CHECK_INTERVAL )); then
  exit 0
fi

# Fetch the latest published version (best-effort); fall back to cached value.
fetched=""
if command -v curl >/dev/null 2>&1; then
  fetched="$(curl -fsSL --max-time 3 "$GIGADUMP_VERSION_URL" 2>/dev/null | jq -r '.version // empty' 2>/dev/null)"
fi
[[ -n "$fetched" ]] && latest="$fetched"
[[ -n "$latest" ]] || exit 0

# Record this check so we don't re-run before the interval elapses.
mkdir -p "$(dirname "$GIGADUMP_UPDATE_CACHE")" 2>/dev/null || true
printf '{"last_check": %s, "latest": "%s"}\n' "${now:-0}" "$latest" > "$GIGADUMP_UPDATE_CACHE" 2>/dev/null || true

# Notify only if the latest is strictly newer than installed (SemVer via sort -V).
max="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V 2>/dev/null | tail -1)"
if [[ "$latest" != "$installed" && "$max" == "$latest" ]]; then
  msg="gigadump $latest is available (you have $installed). Update with: claude plugin marketplace update gigadump && claude plugin update gigadump@gigadump — then restart. (Silence: set \"updateNotifications\": false in ~/.config/gigadump/config.json.)"
  printf '{"systemMessage": %s}\n' "$(printf '%s' "$msg" | jq -Rs .)"
fi
exit 0
