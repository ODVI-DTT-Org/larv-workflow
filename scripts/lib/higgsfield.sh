#!/usr/bin/env bash
# Higgsfield CLI access for larv design comps. The only code that invokes the
# Higgsfield CLI. Requires scripts/lib/design_tools.sh sourced first.
# Never calls `auth token` or `auth login`.

HF_MODEL="${LARV_HIGGSFIELD_MODEL:-nano_banana_pro}"
HF_RESOLUTION="2k"

__hf() {
    local bin
    bin="$(design_higgsfield_bin)" || { echo "ERROR: Higgsfield CLI not installed (run /larv:design-setup)" >&2; return 1; }
    "$bin" "$@"
}

hf_account_json() {
    local json
    json="$(__hf account status --json 2>/dev/null)" || return 1
    printf '%s' "$json" | jq -e '.credits != null' >/dev/null 2>&1 || return 1
    printf '%s\n' "$json" | jq -c '{credits, email, subscription_plan_type}'
}

hf_credits() {
    local json value
    json="$(hf_account_json)" || return 1
    value="$(printf '%s' "$json" | jq -r '.credits')" || return 1
    [[ "$value" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$value"
}

hf_cost() {
    local prompt_file="$1" aspect="$2" json value
    json="$(__hf generate cost "$HF_MODEL" --prompt "$(cat "$prompt_file")" \
        --aspect_ratio "$aspect" --resolution "$HF_RESOLUTION" --json 2>/dev/null)" || return 1
    value="$(printf '%s' "$json" | jq -r '.credits')" || return 1
    [[ "$value" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$value"
}

hf_generate_comp() {
    local prompt_file="$1" aspect="$2" out_png="$3" ref="${4:-}"
    local args=(generate create "$HF_MODEL" --prompt "$(cat "$prompt_file")"
                --aspect_ratio "$aspect" --resolution "$HF_RESOLUTION" --wait --json)
    [ -n "$ref" ] && args+=(--image-references "$ref")
    local json url id tmp
    json="$(__hf "${args[@]}")" || return 1
    url="$(printf '%s' "$json" | jq -r '[.. | objects | .result_url? // empty] | first // empty')"
    id="$(printf '%s' "$json" | jq -r '[.. | objects | .id? // empty] | first // empty')"
    [ -n "$url" ] || { echo "ERROR: Higgsfield returned no result_url" >&2; return 1; }
    mkdir -p "$(dirname "$out_png")"
    tmp="$out_png.part"
    # Only https downloads (redirects included); file:// is a test-only override.
    local proto="=https"
    [ "${LARV_HIGGSFIELD_ALLOW_FILE_URL:-0}" = "1" ] && proto="=https,file"
    if ! curl -fsSL --proto "$proto" --proto-redir "$proto" -o "$tmp" "$url" || [ ! -s "$tmp" ]; then
        rm -f "$tmp"; return 1
    fi
    mv "$tmp" "$out_png"
    echo "$id"
}
