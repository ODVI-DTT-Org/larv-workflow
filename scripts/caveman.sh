#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEFAULT_CAVEMAN_ALLOWLIST_FILE="$SCRIPT_DIR/caveman-allowlist.txt"

usage() {
    cat <<EOF
Usage: caveman.sh <command> <project-dir> [mode]

Commands:
  resolve <dir> [request] [command]
    Resolve effective Caveman mode from optional request override + optional command guard.
    If a command is provided, the request is ignored unless that command is allowlisted.
    If command is omitted, resolver returns normal by default to avoid unscoped style application.

  resolve-command <dir> <command> [request]
    (deprecated) Resolve effective Caveman mode for one command.
    This command is kept for compatibility; prefer `resolve <dir> [request] [command]`.

  allowlist
    Print the effective Caveman allowlist.

  status <dir>
    Print the resolved session mode and whether normal fallback is active.

  set <dir> <mode>
  clear <dir>

  install-hint
    Print the required dependency and pin recommendation.
EOF
    exit 64
}

STATE_CLI() {
    bash "$PLUGIN_ROOT/scripts/state.sh" "$@"
}

normalize_mode() {
    local normalized
    local candidate
    normalized="$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')"

    if [ -n "$normalized" ]; then
        local words
        words="$(printf "%s" "$normalized" | tr -cs 'a-z' ' ')"
        local prev=""
        for candidate in $words; do
            case "$prev" in
                caveman|style|mode)
                    case "$candidate" in
                        full|lite|ultra|normal|off)
                            normalized="$candidate"
                            break
                            ;;
                    esac
                    ;;
            esac
            prev="$candidate"
        done
    fi

    normalized="$(printf "%s" "$normalized" | tr -cs 'a-z' ' ' | sed -E 's/  +/ /g; s/^ //; s/ $//')"

    case "$normalized" in
        *"caveman full"*) echo "full" ;;
        *"caveman lite"*) echo "lite" ;;
        *"caveman ultra"*) echo "ultra" ;;
        *"caveman normal"*) echo "normal" ;;
        *"caveman off"*) echo "normal" ;;
        full|lite|ultra|normal|off)
            if [ "$normalized" = "off" ]; then
                echo "normal"
            else
                echo "$normalized"
            fi
            ;;
        *) echo "" ;;
    esac
}

normalize_command() {
    local command="$1"
    command="${command#/}"
    command="${command#larv:}"
    command="${command#larv-}"
    echo "$command"
}

command_allows_caveman() {
    local command
    command="$(normalize_command "$1")"

    local allowlist
    local -a allowlist_commands
    local command_candidate
    allowlist="$(default_caveman_allowlist)"
    IFS=',' read -r -a allowlist_commands <<< "$allowlist"
    for command_candidate in "${allowlist_commands[@]}"; do
        command_candidate="$(printf "%s" "$command_candidate" | tr -d '[:space:]')"
        if [ "$command_candidate" = "$command" ]; then
            return 0
        fi
    done
    return 1
}

default_caveman_allowlist() {
    local allowlist_file="${LARV_CAVEMAN_ALLOWLIST_FILE:-$DEFAULT_CAVEMAN_ALLOWLIST_FILE}"

    if [ -n "${LARV_CAVEMAN_ALLOWLIST:-}" ]; then
        tr '[:space:]' ' ' <<< "$LARV_CAVEMAN_ALLOWLIST" \
            | tr ',' '\n' \
            | sed '/^$/d' \
            | tr '\n' ',' \
            | sed 's/,$//'
        return 0
    fi
    if [ -f "$allowlist_file" ]; then
        sed -E 's/#.*$//' "$allowlist_file" \
            | sed '/^[[:space:]]*$/d' \
            | sed 's/[[:space:]]//g' \
            | tr '\n' ',' \
            | sed 's/,$//'
        return 0
    fi
    printf "brainstorm,debug,feature,feature-feedback,feature-how-it-works,feature-onboarding-helper,full"
}

print_caveman_allowlist() {
    printf "Caveman allowlist:\n"
    local allowlist
    local -a allowlist_commands
    local source
    local command_candidate
    allowlist="$(default_caveman_allowlist)"
    if [ -n "${LARV_CAVEMAN_ALLOWLIST:-}" ]; then
        source="LARV_CAVEMAN_ALLOWLIST override"
    elif [ -f "${LARV_CAVEMAN_ALLOWLIST_FILE:-$DEFAULT_CAVEMAN_ALLOWLIST_FILE}" ]; then
        source="shared allowlist file (${LARV_CAVEMAN_ALLOWLIST_FILE:-$DEFAULT_CAVEMAN_ALLOWLIST_FILE})"
    else
        source="built-in fallback"
    fi
    printf "Source: %s\n" "$source"
    IFS=',' read -r -a allowlist_commands <<< "$allowlist"
    for command_candidate in "${allowlist_commands[@]}"; do
        command_candidate="$(printf "%s" "$command_candidate" | tr -d '[:space:]')"
        [ -n "$command_candidate" ] || continue
        printf "  - %s\n" "$command_candidate"
    done
}

caveman_bin() {
    if [ -n "${LARV_CAVEMAN_BIN:-}" ]; then
        echo "$LARV_CAVEMAN_BIN"
        return 0
    fi
    if [ -x "$PLUGIN_ROOT/bundle/caveman/bin/caveman" ]; then
        echo "$PLUGIN_ROOT/bundle/caveman/bin/caveman"
        return 0
    fi
    echo "caveman"
}

caveman_install_hint() {
    local bin
    bin="$(caveman_bin)"
    local version
    version="${LARV_CAVEMAN_VERSION:-1.0.0}"
    printf "Caveman binary expected at %s.\n" "$bin"
    printf "Bundled fallback: %s\n" "$PLUGIN_ROOT/bundle/caveman/bin/caveman"
    printf "Pinned version: %s\n" "$version"
    printf "Override with LARV_CAVEMAN_BIN=/path/to/caveman when using a reviewed external binary.\n"
}

caveman_version() {
    local bin
    local out
    local version
    bin="$(caveman_bin)"
    out="$("$bin" --version 2>/dev/null | head -n 1 || true)"
    version="$(printf "%s" "$out" | grep -Eo '[0-9]+(\.[0-9]+){0,2}' | head -n 1 || true)"
    printf "%s\n" "$version"
}

warn_version_drift() {
    local installed
    local expected
    installed="$(caveman_version)"
    expected="${LARV_CAVEMAN_VERSION:-1.0.0}"
    if [ -n "$installed" ] && [ "$installed" != "$expected" ]; then
        printf "Caveman version mismatch (installed=%s, expected=%s). " "$installed" "$expected" >&2
        printf "Fallback style mode remains active, but phrasing can differ across versions.\n" >&2
    fi
}

missing_dependency_message() {
    local mode="$1"
    local bin
    bin="$(caveman_bin)"
    local hint
    hint="$(caveman_install_hint)"
    if [ "${LARV_CAVEMAN_STRICT:-1}" = "0" ]; then
        printf "Caveman %s requested, dependency unavailable (%s).\nFallback status: continuing in normal output.\n%s\n" "$mode" "$bin" "$hint" >&2
    else
        printf "Caveman %s requested, dependency unavailable (%s).\nFallback status: blocked by strict mode; install Caveman or set LARV_CAVEMAN_STRICT=0 only for deterministic compatibility tests.\n%s\n" "$mode" "$bin" "$hint" >&2
    fi
}

ensure_dependency() {
    local mode="$1"
    local bin
    bin="$(caveman_bin)"
    if [ "$mode" = "normal" ]; then
        return 0
    fi
    if command -v "$bin" >/dev/null 2>&1; then
        if [ "${LARV_CAVEMAN_WARN_ON_VERSION_MISMATCH:-1}" != "0" ]; then
            warn_version_drift
        fi
        return 0
    fi
    missing_dependency_message "$mode"
    if [ "${LARV_CAVEMAN_STRICT:-1}" != "0" ]; then
        return 2
    fi
    return 1
}

resolve_mode() {
    local dir="$1"
    local override="$2"
    local requested session_mode

    requested="$(normalize_mode "$override")"
    if [ -z "$requested" ] || [ "$requested" = "normal" ]; then
        session_mode="$(STATE_CLI get-caveman-style "$dir")"
        requested="$session_mode"
    fi

    case "$requested" in
        full|lite|ultra|normal)
            ;;
        *)
            requested="normal"
            ;;
    esac

    if ! ensure_dependency "$requested"; then
        if [ "${LARV_CAVEMAN_STRICT:-1}" != "0" ]; then
            return 2
        fi
        requested="normal"
    fi

    echo "$requested"
}

resolve_for_command() {
    local dir="$1"
    local command="$2"
    local request="${3-}"

    if ! command_allows_caveman "$command"; then
        echo "normal"
        return 0
    fi

    local requested
    requested="$(normalize_mode "$request")"
    resolve_mode "$dir" "$requested"
}

resolve_for_request() {
    local dir="$1"
    local request="$2"
    local command="$3"

    if [ -z "$command" ] && [ "${LARV_CAVEMAN_ALLOW_UNSCOPED_RESOLVE:-0}" != "1" ]; then
        echo "normal"
        return 0
    fi
    if [ -n "$command" ] && ! command_allows_caveman "$command"; then
        echo "normal"
        return 0
    fi

    resolve_mode "$dir" "$request"
}

resolve_status() {
    local dir="$1"
    local effective
    if ! effective="$(resolve_mode "$dir" "" 2>/dev/null)"; then
        effective="full-unavailable"
    fi
    printf "session-style=%s effective-style=%s strict=%s\n" "$(STATE_CLI get-caveman-style "$dir")" "$effective" "${LARV_CAVEMAN_STRICT:-1}"
}

set_mode() {
    local dir="$1"
    local mode
    mode="$(normalize_mode "$2")"
    if [ -z "$mode" ]; then
        echo "ERROR: invalid mode: $2" >&2
        return 1
    fi
    STATE_CLI set-caveman-style "$dir" "$mode"
}

clear_mode() {
    STATE_CLI clear-caveman-style "$1"
}

main() {
    local cmd="$1"
    shift

    case "$cmd" in
        resolve)
            [ "$#" -ge 1 ] && [ "$#" -le 3 ] || usage
            resolve_for_request "$1" "${2-}" "${3-}"
            ;;
        resolve-command)
            [ "$#" -ge 2 ] && [ "$#" -le 3 ] || usage
            resolve_for_command "$1" "$2" "${3-}"
            ;;
        allowlist)
            [ "$#" -eq 0 ] || usage
            print_caveman_allowlist
            ;;
        status)
            [ "$#" -eq 1 ] || usage
            resolve_status "$1"
            ;;
        set)
            [ "$#" -eq 2 ] || usage
            set_mode "$1" "$2"
            ;;
        clear)
            [ "$#" -eq 1 ] || usage
            clear_mode "$1"
            ;;
        install-hint)
            [ "$#" -eq 0 ] || usage
            caveman_install_hint
            ;;
        *)
            usage
            ;;
    esac
}

if [ "$#" -eq 0 ]; then
    usage
fi

main "$@"
