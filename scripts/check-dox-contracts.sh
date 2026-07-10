#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: check-dox-contracts.sh <project-dir>" >&2
    exit 64
}

[ "$#" -eq 1 ] || usage
project_dir="${1%/}"
[ -d "$project_dir" ] || { echo "ERROR: project directory not found: $project_dir" >&2; exit 1; }

failures=0

fail() {
    echo "ERROR: $*" >&2
    failures=$((failures + 1))
}

has_file() {
    [ -f "$project_dir/$1" ]
}

check_file() {
    local file="$1"
    has_file "$file" || fail "missing required contract: $file"
}

contracts=(
    "docs/Handsoff.md"
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    ".codex/AGENTS.md"
    ".cursor/rules/larv.mdc"
    "DOCS.md"
    "docs/larv/STATE.yaml"
)

for file in "${contracts[@]}"; do
    check_file "$file"
done

existing_contracts=()
for file in "${contracts[@]}"; do
    if has_file "$file"; then
        existing_contracts+=("$project_dir/$file")
    fi
done

if [ "${#existing_contracts[@]}" -gt 0 ]; then
    if grep -nE '\{\{[A-Za-z0-9_.:-]+\}\}' "${existing_contracts[@]}"; then
        fail "unresolved template token found in generated contracts"
    fi
    if grep -nE '\b(Opus|Sonnet|Haiku)\b' "${existing_contracts[@]}"; then
        fail "model-specific wording found in generated contracts"
    fi
    if grep -nE '_\([^)]*TBD[^)]*\)_|\bTBD\b' "${existing_contracts[@]}"; then
        fail "raw TBD placeholder found in generated contracts"
    fi
fi

starting_files=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    ".codex/AGENTS.md"
    ".cursor/rules/larv.mdc"
)

for file in "${starting_files[@]}"; do
    has_file "$file" || continue
    path="$project_dir/$file"
    lines="$(wc -l < "$path" | tr -d ' ')"
    if [ "$lines" -gt 85 ]; then
        fail "$file is too long for a routing contract: ${lines} lines"
    fi
    grep -q "Read .*before editing\|Start Here" "$path" || fail "$file missing start/read-before-edit guidance"
    grep -q "Nearest Contract Wins\|Nearest contract wins" "$path" || fail "$file missing nearest-contract routing"
    grep -qi "freshness\|Only update local contracts" "$path" || fail "$file missing freshness guidance"
    grep -qi "dirty worktree\|Preserve unrelated user changes" "$path" || fail "$file missing dirty-worktree safety"
    grep -qi "regenerat" "$path" || fail "$file missing generated-file regeneration guidance"
    grep -q "docs/larv/07-runtime/sandbox-url.txt" "$path" || fail "$file missing sandbox URL routing"
    grep -q "docs/Handsoff.md" "$path" || fail "$file missing Handsoff routing"
done

if has_file "docs/Handsoff.md"; then
    grep -qi "regenerat" "$project_dir/docs/Handsoff.md" || fail "docs/Handsoff.md missing generated-file regeneration guidance"
    grep -qi "hotfix\|follow-up" "$project_dir/docs/Handsoff.md" || fail "docs/Handsoff.md missing hotfix/follow-up routing"
fi

runtime_file="$project_dir/docs/larv/07-runtime/sandbox-url.txt"
state_file="$project_dir/docs/larv/STATE.yaml"
if [ -s "$runtime_file" ]; then
    runtime_url="$(head -n 1 "$runtime_file" | awk '{$1=$1; print}')"
    case "$runtime_url" in
        http://*|https://*) ;;
        *) fail "sandbox-url.txt does not contain an http(s) URL: $runtime_url"; runtime_url="" ;;
    esac
    if [ -n "$runtime_url" ]; then
        runtime_base="$(printf "%s\n" "$runtime_url" | sed -E 's#^(https?://[^/]+).*$#\1#; s#/$##')"
        runtime_host="$(printf "%s\n" "$runtime_base" | sed -E 's#^https?://([^/:]+).*$#\1#')"
        for file in "docs/Handsoff.md" "AGENTS.md" "CLAUDE.md" "GEMINI.md" ".codex/AGENTS.md" ".cursor/rules/larv.mdc"; do
            has_file "$file" || continue
            grep -q "$runtime_host" "$project_dir/$file" || fail "$file does not mention runtime host $runtime_host"
            if grep -q "sandbox.example.com" "$project_dir/$file"; then
                fail "$file leaks sandbox.example.com while runtime URL data exists"
            fi
        done
        if [ -f "$state_file" ] && command -v yq >/dev/null 2>&1; then
            state_url="$(yq -r '.sandbox.app_url // ""' "$state_file" 2>/dev/null || true)"
            if [ -n "$state_url" ] && [ "$state_url" != "null" ]; then
                state_base="$(printf "%s\n" "$state_url" | sed -E 's#^(https?://[^/]+).*$#\1#; s#/$##')"
                [ "$state_base" = "$runtime_base" ] || fail "STATE sandbox.app_url ($state_base) disagrees with sandbox-url.txt ($runtime_base)"
            fi
        fi
    fi
fi

if [ "$failures" -gt 0 ]; then
    echo "DOX contract check failed with $failures issue(s)." >&2
    exit 1
fi

echo "DOX contract check passed for $project_dir"
