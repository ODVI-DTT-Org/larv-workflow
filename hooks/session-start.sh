#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ -f docs/larv/STATE.yaml ] || [ -f docs/Handsoff.md ]; then
    cat <<'MSG'
<larv-reminder>
This directory is managed by larv. Read docs/Handsoff.md before implementation work.
If implementing slices, run docs/Handsoff/bootstrap-sandbox.md before app code edits unless docs/larv/07-runtime/sandbox-url.txt already exists.
</larv-reminder>
MSG
    if [ -x "$PLUGIN_ROOT/scripts/headroom-combo.sh" ]; then
        bash "$PLUGIN_ROOT/scripts/headroom-combo.sh" status "$PWD" || true
    fi
fi
