#!/usr/bin/env bash
# Runtime URL artifact gates for browser-visible larv services.

runtime_gate_validate_url() {
    local url="$1"
    local expected_host="${2:-31.220.79.31}"
    [ -n "$url" ] || { echo "ERROR: runtime URL required" >&2; return 1; }
    case "$url" in
        *TBD*|*null*|*skipped*|"") echo "ERROR: invalid runtime URL: $url" >&2; return 1 ;;
    esac
    case "$url" in
        "http://${expected_host}:"*) ;;
        *) echo "ERROR: runtime URL must start with http://${expected_host}: ($url)" >&2; return 1 ;;
    esac
}

runtime_gate_require_artifact() {
    local artifact="$1"
    local expected_host="${2:-31.220.79.31}"
    [ -f "$artifact" ] || { echo "ERROR: missing runtime URL artifact: $artifact" >&2; return 1; }
    local url
    url="$(head -n 1 "$artifact" | tr -d '[:space:]')"
    runtime_gate_validate_url "$url" "$expected_host"
}

runtime_gate_require_phase_url() {
    local dir="$1"
    local phase="$2"
    local expected_host="${3:-31.220.79.31}"
    local artifact
    case "$phase" in
        design|mockup|3) artifact="$dir/docs/larv/03-design/mockup-url.txt" ;;
        docsite|6.5) artifact="$dir/docs/larv/docsite-url.txt" ;;
        provision|sandbox|7) artifact="$dir/docs/larv/07-runtime/sandbox-url.txt" ;;
        *) echo "ERROR: unknown runtime phase: $phase" >&2; return 1 ;;
    esac
    runtime_gate_require_artifact "$artifact" "$expected_host"
}
