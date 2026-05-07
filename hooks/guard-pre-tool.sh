#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"
file_path="$(printf "%s" "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

[ -n "$file_path" ] || exit 0

case "$file_path" in
    .env|.env.*|*/.env|*/.env.*|*id_rsa*|*id_ed25519*|*secret*|*token*|*credentials*)
        echo "larv guard: refusing likely secret edit at '$file_path'. Put production secrets in Laravel Cloud or a secret manager, not git." >&2
        exit 2
        ;;
esac

case "$file_path" in
    app/*|bootstrap/*|config/*|database/*|resources/*|routes/*|tests/*|composer.json|package.json|vite.config.*)
        if [ -f docs/Handsoff.md ] && [ ! -s docs/larv/07-runtime/sandbox-url.txt ]; then
            echo "larv guard: app code edits require sandbox bootstrap first. Run docs/Handsoff/bootstrap-sandbox.md before implementing slices." >&2
            exit 2
        fi
        ;;
esac

exit 0
