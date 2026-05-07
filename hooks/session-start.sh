#!/usr/bin/env bash
set -euo pipefail

if [ -f docs/larv/STATE.yaml ] || [ -f docs/Handsoff.md ]; then
    cat <<'MSG'
<larv-reminder>
This directory is managed by larv. Read docs/Handsoff.md before implementation work.
If implementing slices, run docs/Handsoff/bootstrap-sandbox.md before app code edits unless docs/larv/07-runtime/sandbox-url.txt already exists.
</larv-reminder>
MSG
fi
