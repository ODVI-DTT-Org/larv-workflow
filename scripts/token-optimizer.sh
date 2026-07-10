#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_FILE="${LARV_TOKEN_OPTIMIZER_POLICY:-$PLUGIN_ROOT/bundle/TOKEN_OPTIMIZERS.yaml}"

usage() {
    cat <<EOF
Usage: token-optimizer.sh <status|json|measure|run> <project-dir> [file|-|-- optimizer-args...]

Evaluates optional Headroom/LeanCTX token optimizers through larv's strict
safety gate. Direct optimizer use outside this script is blocked by hooks.
EOF
    exit 64
}

truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON|enabled|ENABLED) return 0 ;;
        *) return 1 ;;
    esac
}

policy_value() {
    local name="$1"
    local key="$2"
    yq -r ".\"$name\".$key // \"\"" "$POLICY_FILE"
}

approved_path_prefixes() {
    local name="$1"
    yq -r ".\"$name\".approved_path_prefixes[]? // \"\"" "$POLICY_FILE" | while IFS= read -r prefix; do
        prefix="${prefix//\$\{HOME\}/$HOME}"
        prefix="${prefix//\$HOME/$HOME}"
        printf "%s\n" "$prefix"
    done
}

candidate_bin() {
    local name="$1"
    case "$name" in
        lean-ctx) printf "%s\n" "${LARV_LEANCTX_BIN:-lean-ctx}" ;;
        headroom)
            if [ -n "${LARV_HEADROOM_BIN:-}" ]; then
                printf "%s\n" "$LARV_HEADROOM_BIN"
            elif [ -x "$PLUGIN_ROOT/.larv-tools/headroom/venv/bin/headroom" ]; then
                printf "%s\n" "$PLUGIN_ROOT/.larv-tools/headroom/venv/bin/headroom"
            else
                printf "%s\n" "headroom"
            fi
            ;;
        *) printf "%s\n" "$name" ;;
    esac
}

resolve_bin() {
    local bin="$1"
    if [[ "$bin" == */* ]]; then
        [ -x "$bin" ] || return 1
        readlink -f "$bin"
    else
        command -v "$bin" 2>/dev/null | xargs -r readlink -f
    fi
}

extract_version() {
    local bin="$1"
    "$bin" --version 2>/dev/null | head -n 1 | grep -Eo '[0-9]+(\.[0-9]+){0,2}' | head -n 1 || true
}

hash_matches() {
    local bin="$1"
    local expected="$2"
    local actual
    expected="${expected#sha256:}"
    [ -n "$expected" ] || return 1
    case "$expected" in
        REPLACE_WITH_REVIEWED_*|unknown|UNKNOWN|todo|TODO) return 1 ;;
    esac
    actual="$(sha256sum "$bin" | awk '{print $1}')"
    [ "$actual" = "$expected" ]
}

path_approved() {
    local name="$1"
    local bin="$2"
    local prefix
    while IFS= read -r prefix; do
        [ -n "$prefix" ] || continue
        prefix="$(readlink -f "$prefix" 2>/dev/null || printf "%s" "$prefix")"
        case "$bin" in
            "$prefix"/*|"$prefix") return 0 ;;
        esac
    done < <(approved_path_prefixes "$name")
    return 1
}

leanctx_safe_env() {
    truthy "${LEANCTX_SETUP:-}" && return 1
    truthy "${LEANCTX_ONBOARDING:-}" && return 1
    truthy "${LEANCTX_UPDATE_CHECKS:-}" && return 1
    truthy "${LEANCTX_STATS:-}" && return 1
    truthy "${LEANCTX_TELEMETRY:-}" && return 1
    truthy "${LEANCTX_SHELL_HOOKS:-}" && return 1
    return 0
}

headroom_safe_env() {
    truthy "${HEADROOM_WRAP:-}" && return 1
    truthy "${HEADROOM_PROXY:-}" && return 1
    truthy "${HEADROOM_LEARNING:-}" && return 1
    truthy "${HEADROOM_MEMORY:-}" && return 1
    truthy "${HEADROOM_TELEMETRY:-}" && return 1
    truthy "${HEADROOM_DOCKER_WRAPPER:-}" && return 1
    return 0
}

safe_mode_has() {
    local safe_mode="$1"
    local needle="$2"
    case ",$safe_mode," in
        *",$needle,"*) return 0 ;;
        *) return 1 ;;
    esac
}

headroom_workspace_safe() {
    local project_dir="$1"
    local workspace="${HEADROOM_WORKSPACE_DIR:-$project_dir/docs/larv/headroom}"
    local project_real workspace_real allowed_real

    [ -n "$workspace" ] || return 1
    project_real="$(readlink -f "$project_dir" 2>/dev/null || return 1)"
    workspace_real="$(readlink -m "$workspace" 2>/dev/null || return 1)"
    allowed_real="$(readlink -m "$project_real/docs/larv/headroom" 2>/dev/null || return 1)"

    case "$workspace_real" in
        "$allowed_real"|"$allowed_real"/*) return 0 ;;
        *) return 1 ;;
    esac
}

inspect_candidate() {
    local name="$1"
    local project_dir="$2"
    local bin_ref bin version expected_version expected_hash safe_mode
    version=""

    [ -d "$project_dir" ] || {
        printf "%s\tunsafe\tproject directory not found\t\t\t\n" "$name"
        return 0
    }

    expected_version="$(policy_value "$name" "approved_version")"
    expected_hash="$(policy_value "$name" "sha256")"
    safe_mode="$(policy_value "$name" "safe_mode")"
    [ -n "$expected_version" ] || {
        printf "%s\tunsafe\tmissing policy metadata\t\t\t\n" "$name"
        return 0
    }

    bin_ref="$(candidate_bin "$name")"
    bin="$(resolve_bin "$bin_ref" || true)"
    [ -n "$bin" ] || {
        printf "%s\tunsafe\tnot found: %s\t\t\t%s\n" "$name" "$bin_ref" "$safe_mode"
        return 0
    }

    path_approved "$name" "$bin" || {
        printf "%s\tunsafe\tinstall path not approved: %s\t%s\t\t%s\n" "$name" "$bin" "$bin" "$safe_mode"
        return 0
    }

    hash_matches "$bin" "$expected_hash" || {
        printf "%s\tunsafe\thash mismatch or unreviewed hash\t%s\t%s\t%s\n" "$name" "$bin" "$version" "$safe_mode"
        return 0
    }

    version="$(extract_version "$bin")"
    [ "$version" = "$expected_version" ] || {
        printf "%s\tunsafe\tversion mismatch: installed=%s expected=%s\t%s\t%s\t%s\n" "$name" "${version:-unknown}" "$expected_version" "$bin" "${version:-unknown}" "$safe_mode"
        return 0
    }

    case "$name" in
        lean-ctx)
            leanctx_safe_env || {
                printf "%s\tunsafe\tunsafe lean-ctx mode requested\t%s\t%s\t%s\n" "$name" "$bin" "$version" "$safe_mode"
                return 0
            }
            ;;
        headroom)
            headroom_safe_env || {
                printf "%s\tunsafe\tunsafe headroom mode requested\t%s\t%s\t%s\n" "$name" "$bin" "$version" "$safe_mode"
                return 0
            }
            if safe_mode_has "$safe_mode" "workspace-bounded-state"; then
                headroom_workspace_safe "$project_dir" || {
                    printf "%s\tunsafe\tworkspace outside project or missing: %s\t%s\t%s\t%s\n" "$name" "${HEADROOM_WORKSPACE_DIR:-unset}" "$bin" "$version" "$safe_mode"
                    return 0
                }
            fi
            ;;
    esac

    printf "%s\tsafe\tpassed strict optimizer gate\t%s\t%s\t%s\n" "$name" "$bin" "$version" "$safe_mode"
}

evaluate_gate() {
    local project_dir="$1"
    local candidates="${LARV_TOKEN_OPTIMIZER_CANDIDATES:-lean-ctx,headroom}"
    local name line failures=""

    IFS=',' read -ra names <<<"$candidates"
    for name in "${names[@]}"; do
        [ -n "$name" ] || continue
        line="$(inspect_candidate "$name" "$project_dir")"
        IFS=$'\t' read -r cname state reason bin version safe_mode <<<"$line"
        if [ "$state" = "safe" ]; then
            printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$cname" "$state" "$reason" "$bin" "$version" "$safe_mode"
            return 0
        fi
        failures="${failures}${failures:+; }$cname: $reason"
    done

    printf "none\tfallback\t%s\t\t\t\n" "${failures:-no candidates configured}"
}

print_status() {
    local project_dir="$1"
    local line name state reason bin version safe_mode
    line="$(evaluate_gate "$project_dir")"
    IFS=$'\t' read -r name state reason bin version safe_mode <<<"$line"
    echo "Token optimizer gate:"
    if [ "$state" = "safe" ]; then
        echo "Optimizer: $name (safe)"
        echo "Reason: $reason"
        echo "Binary: $bin"
        echo "Version: $version"
        echo "safe_mode=$safe_mode"
    else
        echo "Optimizer: none (fallback)"
        echo "Reason: $reason"
    fi
}

print_json() {
    local project_dir="$1"
    local line name state reason bin version safe_mode selected status fallback_reason
    line="$(evaluate_gate "$project_dir")"
    IFS=$'\t' read -r name state reason bin version safe_mode <<<"$line"
    selected="$name"
    status="$state"
    fallback_reason="$reason"
    if [ "$state" = "safe" ]; then
        fallback_reason=""
    fi
    jq -n \
        --arg selected "$selected" \
        --arg status "$status" \
        --arg reason "$reason" \
        --arg fallback_reason "$fallback_reason" \
        --arg binary "$bin" \
        --arg version "$version" \
        --arg safe_mode "$safe_mode" \
        '{selected: $selected, status: $status, reason: $reason, fallback_reason: $fallback_reason, binary: $binary, version: $version, safe_mode: $safe_mode}'
}

run_optimizer() {
    local project_dir="$1"
    shift
    [ "${1:-}" = "--" ] && shift
    local line name state reason bin version safe_mode
    line="$(evaluate_gate "$project_dir")"
    IFS=$'\t' read -r name state reason bin version safe_mode <<<"$line"
    if [ "$state" != "safe" ]; then
        echo "larv token optimizer: no safe optimizer selected ($reason)" >&2
        return 2
    fi
    case "$name" in
        headroom)
            export HEADROOM_WORKSPACE_DIR="${HEADROOM_WORKSPACE_DIR:-$project_dir/docs/larv/headroom}"
            export HEADROOM_CONFIG_DIR="${HEADROOM_CONFIG_DIR:-$project_dir/docs/larv/headroom/config}"
            case "${1:-}" in
                wrap|unwrap|proxy|dashboard|learn|memory|mcp|install|init)
                    echo "larv token optimizer: blocked unsafe Headroom subcommand '${1:-}'" >&2
                    return 2
                    ;;
            esac
            exec "$bin" "$@"
            ;;
        lean-ctx) exec "$bin" "$@" ;;
        *) echo "larv token optimizer: unsupported optimizer '$name'" >&2; return 2 ;;
    esac
}

measure_optimizer() {
    local project_dir="$1"
    local input_path="${2:--}"
    local line name state reason bin version safe_mode text
    line="$(evaluate_gate "$project_dir")"
    IFS=$'\t' read -r name state reason bin version safe_mode <<<"$line"
    if [ "$state" != "safe" ]; then
        echo "larv token optimizer: no safe optimizer selected ($reason)" >&2
        return 2
    fi
    if [ "$name" != "headroom" ]; then
        echo "larv token optimizer: measurement currently requires Headroom (selected $name)" >&2
        return 2
    fi
    export HEADROOM_WORKSPACE_DIR="${HEADROOM_WORKSPACE_DIR:-$project_dir/docs/larv/headroom}"
    export HEADROOM_CONFIG_DIR="${HEADROOM_CONFIG_DIR:-$project_dir/docs/larv/headroom/config}"
    if [ "$input_path" = "-" ]; then
        text="$(cat)"
    else
        [ -f "$input_path" ] || { echo "larv token optimizer: input file not found: $input_path" >&2; return 2; }
        text="$(cat "$input_path")"
    fi

    local python_bin
    python_bin="$(dirname "$bin")/python"
    if [ ! -x "$python_bin" ]; then
        python_bin="python3"
    fi

    "$python_bin" - "$text" <<'PY'
import json
import re
import sys

text = sys.argv[1]
target_savings = 0.50

def estimate_tokens(value: str) -> int:
    parts = re.findall(r"\w+|[^\w\s]", value, flags=re.UNICODE)
    return max(1, len(parts)) if value else 0

def trim_line(line: str, limit: int = 180) -> str:
    line = re.sub(r"\s+", " ", line.strip())
    if len(line) <= limit:
        return line
    return line[: limit - 1].rstrip() + "..."

def pack_diff(value: str) -> str:
    kept = ["# larv context pack: git diff summary"]
    for line in value.splitlines():
        raw = line.rstrip()
        if raw.startswith(("diff --git ", "index ", "--- ", "+++ ", "@@ ")):
            kept.append(trim_line(raw, 220))
        elif raw.startswith(("+", "-")) and not raw.startswith(("+++", "---")):
            body = raw[1:].strip()
            if body:
                kept.append(raw[:1] + trim_line(body))
    return "\n".join(kept)

def pack_source(value: str) -> str:
    kept = ["# larv context pack: source outline"]
    patterns = [
        r"^\s*(namespace|use)\s+",
        r"^\s*(class|interface|trait|enum)\s+",
        r"^\s*(public|protected|private)\s+(static\s+)?(function|\$)",
        r"^\s*function\s+",
        r"^\s*(it|test)\(",
        r"^\s*->(assert|set|call|get|post|put|delete)",
        r"^\s*expect\(",
        r"^\s*<([a-zA-Z0-9_.:-]+)",
        r"^\s*@(?:if|foreach|class|selected|else|endif|endforeach)",
        r"^\s*[.#]?[a-zA-Z][^{;]{0,80}\{\s*$",
    ]
    combined = re.compile("|".join(f"(?:{p})" for p in patterns))
    previous_blank = False
    for line in value.splitlines():
        stripped = line.strip()
        if not stripped:
            if not previous_blank and len(kept) > 1:
                kept.append("")
            previous_blank = True
            continue
        previous_blank = False
        if combined.search(line):
            kept.append(trim_line(line))
    if len(kept) == 1:
        return pack_text(value)
    return "\n".join(kept)

def pack_text(value: str) -> str:
    kept = ["# larv context pack: text outline"]
    for line in value.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith(("#", "-", "*", "|", ">", "```")) or re.match(r"^\d+[\.)]\s+", stripped):
            kept.append(trim_line(stripped))
        elif len(kept) < 30:
            kept.append(trim_line(stripped))
    return "\n".join(kept)

def context_pack(value: str, before_tokens: int) -> str:
    if re.search(r"^diff --git ", value, flags=re.MULTILINE):
        packed = pack_diff(value)
    elif re.search(r"(class\s+\w+|function\s+\w+|<x-|<section|@foreach|@if|it\(|expect\(|^\s*[.#][\w-]+\s*\{)", value, flags=re.MULTILINE):
        packed = pack_source(value)
    else:
        packed = pack_text(value)

    budget = max(1, int(before_tokens * (1.0 - target_savings)))
    lines = packed.splitlines()
    while estimate_tokens("\n".join(lines)) > budget and len(lines) > 4:
        lines = lines[: max(4, int(len(lines) * 0.80))]
        lines.append("# trimmed to token target; read original file for exact bytes")
    return "\n".join(lines)

before = estimate_tokens(text)
after = before
saved = 0
ratio = 0.0
method = "estimate"
exact_replay = "true"
target_met = "no"
transforms = []

try:
    from headroom import CompressConfig, compress

    result = compress(
        [{"role": "user", "content": text}],
        optimize=True,
        config=CompressConfig(
            compress_user_messages=True,
            compress_system_messages=True,
            protect_recent=0,
            protect_analysis_context=True,
            min_tokens_to_compress=1,
        ),
    )
    before = int(result.tokens_before)
    after = int(result.tokens_after)
    saved = int(result.tokens_saved)
    ratio = float(result.compression_ratio)
    method = "headroom"
    transforms = list(getattr(result, "transforms_applied", []) or [])
except Exception:
    saved = max(0, before - after)
    ratio = (after / before) if before else 0.0

if before and (saved / before) < target_savings:
    packed = context_pack(text, before)
    packed_after = estimate_tokens(packed)
    if packed_after < after:
        after = packed_after
        saved = max(0, before - after)
        ratio = saved / before if before else 0.0
        method = f"{method}+larv-context-pack"
        exact_replay = "false"

if before and (saved / before) >= target_savings:
    target_met = "yes"

percent = (saved / before * 100.0) if before else 0.0
print("Token measurement:")
print(f"method={method}")
print(f"tokens_before={before}")
print(f"tokens_after={after}")
print(f"tokens_saved={saved}")
print(f"savings_percent={percent:.1f}")
print(f"compression_ratio={ratio:.3f}")
print(f"target_savings_percent={target_savings * 100:.1f}")
print(f"target_met={target_met}")
print(f"exact_replay={exact_replay}")
if transforms:
    print("headroom_transforms=" + ",".join(transforms))
PY
}

main() {
    [ -f "$POLICY_FILE" ] || { echo "ERROR: optimizer policy not found at $POLICY_FILE" >&2; exit 1; }
    [ "$#" -ge 2 ] || usage
    local cmd="$1"
    local project_dir="$2"
    shift 2
    case "$cmd" in
        status) print_status "$project_dir" ;;
        json) print_json "$project_dir" ;;
        measure) measure_optimizer "$project_dir" "${1:--}" ;;
        run) run_optimizer "$project_dir" "$@" ;;
        *) usage ;;
    esac
}

main "$@"
