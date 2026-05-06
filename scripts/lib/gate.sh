#!/usr/bin/env bash
# Gate UX per spec §4.2 and §4.3.

__gate_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

# soft_gate <dir> <phase_num> <phase_name> <summary> <changed_files_csv>
# Prints summary + changed files. Auto-continues unless LARV_GATE_PAUSE=1.
soft_gate() {
    local dir="$1" phase_num="$2" phase_name="$3" summary="$4" changed_csv="$5"
    echo
    echo "[Phase $phase_num — $phase_name]"
    echo
    echo "$summary"
    echo
    echo "Changed files:"
    echo "$changed_csv" | tr ',' '\n' | sed 's/^/  /'
    echo

    if [ "${LARV_GATE_PAUSE:-0}" = "1" ]; then
        echo "Paused. Type 'continue' to advance, 'pause' to stay, or 'back' to redo previous phase:"
        local reply
        IFS= read -r reply
        case "$reply" in
            continue) return 0 ;;
            pause) return 2 ;;
            back) return 3 ;;
            *) return 2 ;;
        esac
    else
        echo "Auto-continue in 30s. Reply 'pause' to review or 'back' to redo previous phase."
        return 0
    fi
}

# hard_gate <dir> <phase_num> <prompt>
# Reads from stdin. Returns 0 only if user types 'approved'.
hard_gate() {
    local dir="$1" phase_num="$2" prompt="$3"
    echo
    echo "[Hard gate — Phase $phase_num]"
    echo "$prompt"
    echo
    echo "Type 'approved' to continue:"
    local reply
    IFS= read -r reply
    if [ "$reply" = "approved" ]; then
        return 0
    fi
    echo "Gate not approved (received: '$reply'). Stopping." >&2
    return 1
}

# routing_menu <dir>
# Prints menu, reads choice from stdin, updates STATE.yaml.execution.mode.
routing_menu() {
    local dir="$1"
    local plugin_root
    plugin_root="$(__gate_plugin_root)"
    cat "$plugin_root/templates/routing-menu.md.tmpl"
    echo
    echo "Choose: same-session | subagents | handoff"
    local choice
    IFS= read -r choice
    local mode
    case "$choice" in
        same-session) mode="executing-same-session" ;;
        subagents)    mode="executing-subagents" ;;
        handoff)      mode="handed-off-external" ;;
        *) echo "ERROR: invalid choice: $choice" >&2; return 1 ;;
    esac
    bash "$plugin_root/scripts/state.sh" set-mode "$dir" "$mode"
    echo "[Routing] STATE.yaml.execution.mode = $mode"
}
