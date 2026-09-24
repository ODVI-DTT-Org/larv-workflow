#!/usr/bin/env bash
# Test double for the Higgsfield CLI. Logs every call; never touches network.
# Env: STUB_DIR (required), STUB_CREDITS (default 79), STUB_SIGNED_OUT=1 (account + cost fail),
#      STUB_FAIL_CREATE=1, STUB_COST (default 2)
set -u
printf '%s\n' "$*" >>"$STUB_DIR/hf.log"
case "$1 ${2:-}" in
    "account status")
        [ "${STUB_SIGNED_OUT:-0}" = "1" ] && { echo "not logged in" >&2; exit 1; }
        printf '{"credits":%s,"email":"dtt@oakdriveventures.com","subscription_plan_type":"lite"}\n' "${STUB_CREDITS:-79}"
        ;;
    "generate cost")
        [ "${STUB_SIGNED_OUT:-0}" = "1" ] && { echo "not logged in" >&2; exit 1; }
        printf '{"credits":%s}\n' "${STUB_COST:-2}"
        ;;
    "generate create")
        [ "${STUB_FAIL_CREATE:-0}" = "1" ] && { echo "insufficient credits" >&2; exit 1; }
        n=$(ls "$STUB_DIR"/result-*.png 2>/dev/null | wc -l)
        out="$STUB_DIR/result-$n.png"
        printf '\x89PNG\r\n\x1a\nstub' >"$out"
        # record the exact prompt argument for verbatim checks
        prev=""; for a in "$@"; do [ "$prev" = "--prompt" ] && printf '%s' "$a" >"$STUB_DIR/last-prompt.txt"; prev="$a"; done
        printf '[{"id":"job-%s","status":"completed","result_url":"file://%s"}]\n' "$n" "$out"
        ;;
    "auth token")
        echo "FORBIDDEN" >&2; exit 99 ;;
    *) echo "stub: unhandled $*" >&2; exit 2 ;;
esac
