#!/usr/bin/env bash
# Readiness check and installer for the larv Impeccable + Higgsfield design round.
# check exit codes: 0 ready, 3 zero-credit fallback only, 1 hard failure.
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$PLUGIN_ROOT/scripts/lib/design_tools.sh"
. "$PLUGIN_ROOT/scripts/lib/higgsfield.sh"

HF_VERSION="1.1.26"
HF_SHA256="5d666fae70c99b7388690191a649d1487962250ed50820e079edfd1ffac7bf5b"
HF_ARCHIVE_URL="${LARV_HIGGSFIELD_ARCHIVE_URL:-https://github.com/higgsfield-ai/cli/releases/download/v${HF_VERSION}/hf_${HF_VERSION}_linux_amd64.tar.gz}"
HF_DEST="$HOME/.local/share/larv/higgsfield"
CAP="${LARV_HIGGSFIELD_CREDIT_CAP:-10}"
LOGIN_HINT="! $HF_DEST/higgsfield auth login   (no --port; see README 'Impeccable + Higgsfield design directions')"

usage() {
    cat <<'EOF'
Usage: design-setup.sh <command> [project-dir]

Commands:
  check [dir]   Report readiness. Exit 0 ready, 3 zero-credit fallback only, 1 hard failure
  install       Install the pinned Higgsfield CLI and the vendored Impeccable skill (never signs in)
  help          Show this help
EOF
}

cmd_check() {
    local hard=0 fallback=0 launcher host acct tool
    echo "Design tools check:"
    if launcher="$(design_impeccable_launcher)"; then
        if "$launcher" engine-probe >/dev/null 2>&1; then
            echo "  ok: impeccable engine ($launcher)"
        else
            echo "  missing: impeccable engine (run: $launcher engine-probe)"; hard=1
        fi
    else
        echo "  missing: impeccable skill (run /larv:design-setup)"; hard=1
    fi
    if ! design_higgsfield_bin >/dev/null; then
        echo "  fallback: higgsfield not installed (run /larv:design-setup)"; fallback=1
    elif ! acct="$(hf_account_json)"; then
        echo "  fallback: higgsfield not signed in; user runs: $LOGIN_HINT"; fallback=1
    else
        local credits email plan
        credits="$(jq -r '.credits' <<<"$acct")"
        email="$(jq -r '.email' <<<"$acct")"
        plan="$(jq -r '.subscription_plan_type' <<<"$acct")"
        if [ "$credits" -lt "$CAP" ]; then
            echo "  fallback: $credits credits left (cap $CAP) on $email"; fallback=1
        else
            echo "  ok: higgsfield $email ($plan, $credits credits)"
        fi
    fi
    if host="$(design_public_host)"; then
        echo "  ok: public host $host"
    else
        echo "  missing: public host (set LARV_VM_HOST to this server's public IP)"; hard=1
    fi
    for tool in php curl ss setsid jq; do
        command -v "$tool" >/dev/null 2>&1 || { echo "  missing: $tool"; hard=1; }
    done
    [ "$hard" -eq 1 ] && return 1
    [ "$fallback" -eq 1 ] && return 3
    return 0
}

install_higgsfield() {
    if [ -x "$HF_DEST/higgsfield" ]; then
        echo "  ok: higgsfield already installed at $HF_DEST"
        return 0
    fi
    local platform="${LARV_DESIGN_SETUP_UNAME:-$(uname -sm)}" tmp
    if [ "$platform" != "Linux x86_64" ]; then
        echo "ERROR: no pinned Higgsfield checksum for $platform; install it manually and set LARV_HIGGSFIELD_BIN" >&2
        return 1
    fi
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/hf.tgz" "$HF_ARCHIVE_URL" \
        || ! echo "$HF_SHA256  $tmp/hf.tgz" | sha256sum -c - >/dev/null 2>&1; then
        echo "ERROR: Higgsfield download failed or checksum mismatch; nothing installed" >&2
        rm -rf "$tmp"; return 1
    fi
    (
        umask 077
        mkdir -p "$HF_DEST/bin"
        tar -xzf "$tmp/hf.tgz" -C "$tmp" hf
        mv "$tmp/hf" "$HF_DEST/bin/higgsfield"
        cp "$PLUGIN_ROOT/templates/higgsfield-wrapper.sh" "$HF_DEST/higgsfield"
        chmod 700 "$HF_DEST/bin/higgsfield" "$HF_DEST/higgsfield"
    )
    rm -rf "$tmp"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HF_DEST/higgsfield" "$HOME/.local/bin/higgsfield"
    echo "  ok: higgsfield $HF_VERSION installed at $HF_DEST"
}

install_impeccable() {
    local src="$PLUGIN_ROOT/bundle/impeccable" target
    [ -d "$src" ] || { echo "ERROR: bundle/impeccable missing" >&2; return 1; }
    for target in "$HOME/.claude/skills/impeccable" "$HOME/.agents/skills/impeccable"; do
        if [ -e "$target" ] && [ "${LARV_DESIGN_SETUP_FORCE:-0}" != "1" ]; then
            echo "  ok: impeccable skill kept at $target"
            continue
        fi
        if [ -e "$target" ]; then
            local bk="$HOME/.local/share/larv/backups/$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$bk"; mv "$target" "$bk/"
            echo "  info: backed up $target to $bk"
        fi
        mkdir -p "$(dirname "$target")"
        cp -a "$src" "$target"
        echo "  ok: impeccable skill installed at $target"
    done
    "$HOME/.claude/skills/impeccable/scripts/impeccable" engine-probe >/dev/null \
        && echo "  ok: impeccable engine ready" \
        || { echo "ERROR: impeccable engine-probe failed (needs network once)" >&2; return 1; }
}

cmd_install() {
    echo "Design tools install:"
    install_higgsfield || return 1
    if [ -z "${LARV_IMPECCABLE_SKILL_DIR:-}" ]; then
        install_impeccable || return 1
    fi
    if ! hf_account_json >/dev/null 2>&1; then
        echo "  next: sign in once (user step): $LOGIN_HINT"
    fi
}

main() {
    local cmd="${1:-help}"
    shift || true
    case "$cmd" in
        check) cmd_check "$@" ;;
        install) cmd_install ;;
        help|-h|--help) usage ;;
        *) usage >&2; exit 64 ;;
    esac
}

main "$@"
