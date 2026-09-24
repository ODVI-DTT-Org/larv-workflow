#!/usr/bin/env bash
# Resolve the shared design tools (Higgsfield wrapper, Impeccable launcher),
# the public host used to announce design boards, and the project slug.
# Sourced by design-setup.sh and design-directions.sh. No side effects.

DESIGN_TOOLS_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

design_higgsfield_bin() {
    if [ -n "${LARV_HIGGSFIELD_BIN:-}" ]; then
        [ -x "$LARV_HIGGSFIELD_BIN" ] && { echo "$LARV_HIGGSFIELD_BIN"; return 0; }
        return 1
    fi
    local shared="$HOME/.local/share/larv/higgsfield/higgsfield"
    [ -x "$shared" ] && { echo "$shared"; return 0; }
    command -v higgsfield 2>/dev/null
}

design_impeccable_launcher() {
    if [ -n "${LARV_IMPECCABLE_SKILL_DIR:-}" ]; then
        [ -x "$LARV_IMPECCABLE_SKILL_DIR/scripts/impeccable" ] \
            && { echo "$LARV_IMPECCABLE_SKILL_DIR/scripts/impeccable"; return 0; }
        return 1
    fi
    local c
    for c in "$DESIGN_TOOLS_PLUGIN_ROOT/bundle/impeccable" \
             "$HOME/.claude/skills/impeccable" \
             "$HOME/.agents/skills/impeccable"; do
        [ -x "$c/scripts/impeccable" ] && { echo "$c/scripts/impeccable"; return 0; }
    done
    return 1
}

design_public_host() {
    local host="${LARV_VM_HOST:-}"
    if [ -z "$host" ] || [ "$host" = "sandbox.example.com" ]; then
        host="$( (hostname -I 2>/dev/null || true) | awk '{print $1}')"
    fi
    case "$host" in
        ""|localhost|127.*|sandbox.example.com) return 1 ;;
    esac
    echo "$host"
}

design_slug() {
    local dir="$1" slug=""
    if [ -f "$dir/docs/larv/STATE.yaml" ]; then
        slug="$(yq -r '.project.slug // ""' "$dir/docs/larv/STATE.yaml" 2>/dev/null || true)"
    fi
    if [ -z "$slug" ] || [ "$slug" = "null" ]; then
        slug="$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    fi
    echo "$slug"
}
