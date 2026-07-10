#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"
file_path="$(printf "%s" "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
command_text="$(printf "%s" "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [ -n "$command_text" ]; then
    if printf "%s" "$command_text" | grep -Eq '(^|[^[:alnum:]_./-])(headroom|lean-ctx)([^[:alnum:]_-]|$)' \
        && ! printf "%s" "$command_text" | grep -q 'scripts/token-optimizer\.sh'; then
        echo "larv guard: direct token optimizer use is blocked. Route Headroom/LeanCTX through scripts/token-optimizer.sh so version, hash, path, telemetry, proxy, and config-write checks run first." >&2
        exit 2
    fi

    if printf "%s" "$command_text" | grep -Eiq '(leanctx|lean-ctx|headroom)' \
        && printf "%s" "$command_text" | grep -Eiq 'curl[^|]*\|[[:space:]]*(sh|bash)'; then
        echo "larv guard: token optimizer curl-pipe-shell installs are blocked. Use scripts/token-optimizer.sh with reviewed pinned metadata." >&2
        exit 2
    fi

    if printf "%s" "$command_text" | grep -Eiq '(npm|pnpm|yarn|pip|pipx)[^;&|]*(install|add)[^;&|]*(leanctx|lean-ctx|headroom|headroom-ai)'; then
        echo "larv guard: direct token optimizer package installs are blocked because lifecycle hooks and postinstall mutations bypass the larv gate." >&2
        exit 2
    fi

    if printf "%s" "$command_text" | grep -Eiq '(leanctx|lean-ctx|headroom)' \
        && printf "%s" "$command_text" | grep -Eiq '(\.bashrc|\.zshrc|\.profile|\.config/autostart|\.claude|\.codex|\.agents)'; then
        echo "larv guard: token optimizer shell hooks, autostart files, and global agent config mutations are blocked." >&2
        exit 2
    fi
fi

[ -n "$file_path" ] || exit 0

case "$file_path" in
    */.bashrc|*/.zshrc|*/.profile|*/.bash_profile|*/.config/autostart/*|*/.claude/*|*/.codex/*|*/.agents/*)
        echo "larv guard: shell hooks, autostart files, and global agent config mutations are blocked so token optimizers cannot bypass scripts/token-optimizer.sh." >&2
        exit 2
        ;;
esac

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
