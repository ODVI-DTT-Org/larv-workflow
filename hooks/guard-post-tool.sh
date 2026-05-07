#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"
file_path="$(printf "%s" "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

[ -n "$file_path" ] || exit 0

case "$file_path" in
    app/*|bootstrap/*|config/*|database/*|resources/*|routes/*|tests/*|composer.json|package.json|vite.config.*)
        if [ -f docs/Handsoff.md ]; then
            cat <<'MSG'
larv reminder: after app edits, update the matching slice contract:
- append docs/larv/implementation-tracker.yaml
- update docs/larv/STATE.yaml slice status
- write/update IMPLEMENTATION-REPORT-<slice-id>.md
- run the slice Definition of Done before claiming completion
MSG
        fi
        ;;
esac

exit 0
