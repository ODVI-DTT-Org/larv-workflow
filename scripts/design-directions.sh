#!/usr/bin/env bash
# Impeccable directions + Higgsfield comps design round.
# Steps: context seed cost comps board serve pick (see usage).
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$PLUGIN_ROOT/scripts/lib/design_tools.sh"
. "$PLUGIN_ROOT/scripts/lib/higgsfield.sh"

CAP="${LARV_HIGGSFIELD_CREDIT_CAP:-10}"

usage() {
    cat <<'EOF'
Usage: design-directions.sh <step> <project-dir> <out-dir> [arg]

Steps (run in order; the agent authors options.json and prompts/<id>.txt after seed):
  context  Ensure PRODUCT.md (exit 2 NEEDS_PRODUCT_MD when the agent must author it)
  seed     Run Impeccable concept-seed into seed.txt (fallback marker on failure)
  cost     Price every comp card with Higgsfield; exit 4 when over LARV_HIGGSFIELD_CREDIT_CAP
  comps    Generate one Higgsfield comp per comp card (per-card wireframe fallback)
  board    Render board/index.html from options.json and comps
  serve    Serve the board on a public 9000-9499 port (probe before announce)
  pick     Approve the chosen card: pick <dir> <out> <id>
EOF
}

comp_ids() {
    jq -r '.options[] | select((.verdict // "") != "declined") | .id' "$1/options.json"
}

aspect_for() {
    local surface
    surface="$(jq -r --arg id "$2" '.options[] | select(.id == $id) | .surface // "desktop"' "$1/options.json")"
    [ "$surface" = "phone" ] && echo "9:16" || echo "3:2"
}

step_context() {
    local dir="$1" out="$2"
    mkdir -p "$out"
    if [ -f "$dir/PRODUCT.md" ]; then
        echo "context: keep existing $dir/PRODUCT.md"; return 0
    fi
    if [ -f "$dir/docs/larv/00-discuss/product-brief.md" ]; then
        LARV_IMPECCABLE_PRODUCT_ONLY=1 bash "$PLUGIN_ROOT/scripts/impeccable.sh" context "$dir"
        return 0
    fi
    echo "NEEDS_PRODUCT_MD: write $dir/PRODUCT.md from the existing app (Impeccable init ask round), then rerun context"
    return 2
}

step_seed() {
    local dir="$1" out="$2" launcher
    mkdir -p "$out"; rm -f "$out/fallback"
    launcher="$(design_impeccable_launcher)" || { echo "seed-unavailable" >"$out/fallback"; echo "seed: no impeccable launcher; fallback"; return 0; }
    if (cd "$dir" && sh "$launcher" concept-seed --candidate-count 7) >"$out/seed.txt" 2>&1; then
        echo "seed: wrote $out/seed.txt"
    else
        echo "seed-unavailable" >"$out/fallback"
        echo "seed: concept-seed failed; author directions from PRODUCT.md and mark the board as fallback"
    fi
}

step_cost() {
    local dir="$1" out="$2" id c total=0 per='{}'
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    for id in $(comp_ids "$out"); do
        [ -f "$out/comps/$id.png" ] && continue
        [ -f "$out/prompts/$id.txt" ] || { echo "ERROR: missing prompt $out/prompts/$id.txt" >&2; return 1; }
        c="$(hf_cost "$out/prompts/$id.txt" "$(aspect_for "$out" "$id")")" || { echo "ERROR: hf_cost failed for $id (Higgsfield CLI unavailable or errored)" >&2; return 1; }
        per="$(jq -c --arg id "$id" --argjson c "$c" '. + {($id): $c}' <<<"$per")"
        total=$((total + c))
    done
    jq -n --argjson per "$per" --argjson total "$total" --argjson cap "$CAP" \
        '{per_comp: $per, total: $total, cap: $cap}' >"$out/cost.json"
    echo "cost: $total credits for $(jq 'length' <<<"$per") comps (cap $CAP)"
    if [ "$total" -gt "$CAP" ] && [ "${LARV_DESIGN_CONFIRMED_SPEND:-0}" -lt "$total" ]; then
        echo "cost: $total credits exceeds cap $CAP; ask the user, then rerun with LARV_DESIGN_CONFIRMED_SPEND=$total"
        return 4
    fi
}

step_comps() {
    local dir="$1" out="$2" id ref="" aspect job
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    mkdir -p "$out/comps"
    if [ -f "$out/refs/reference.png" ]; then
        if [ ! -f "$out/refs/FICTIONAL-DATA-CONFIRMED" ]; then
            echo "ERROR: $out/refs/reference.png needs $out/refs/FICTIONAL-DATA-CONFIRMED (seeded/fictional data only)" >&2
            return 5
        fi
        ref="$out/refs/reference.png"
    fi
    local signed_in=1
    hf_account_json >/dev/null 2>&1 || signed_in=0
    for id in $(comp_ids "$out"); do
        if [ -f "$out/comps/$id.png" ]; then echo "comps: keep $id"; continue; fi
        if [ "$signed_in" -eq 0 ]; then
            echo "higgsfield-unavailable" >"$out/comps/$id.fallback"; continue
        fi
        aspect="$(aspect_for "$out" "$id")"
        if job="$(hf_generate_comp "$out/prompts/$id.txt" "$aspect" "$out/comps/$id.png" ${ref:+"$ref"})"; then
            rm -f "$out/comps/$id.fallback"
            jq -n --rawfile prompt "$out/prompts/$id.txt" --arg model "$HF_MODEL" \
                --arg aspect "$aspect" --arg res "$HF_RESOLUTION" --arg job "$job" \
                --arg date "$(date +%F)" --arg ref "$ref" \
                '{prompt: $prompt, tool: "Higgsfield CLI", model: $model, aspect_ratio: $aspect,
                  resolution: $res, job_id: $job, generated_on: $date, reference: $ref,
                  approved: false, sample_data: true}' >"$out/comps/$id.json"
            echo "comps: $id done"
        else
            echo "generation-failed" >"$out/comps/$id.fallback"
            echo "comps: $id failed; wireframe card will be shown"
        fi
    done
    [ "$signed_in" -eq 0 ] && echo "comps: Higgsfield unavailable; board uses zero-credit wireframe cards"
    return 0
}

step_pick() {
    local dir="$1" out="$2" id="${3:-}" label
    label="$(jq -r --arg id "$id" '.options[] | select(.id == $id) | .label' "$out/options.json")"
    [ -n "$id" ] && [ -n "$label" ] || { echo "ERROR: unknown option id: $id" >&2; return 1; }
    if [ -f "$out/comps/$id.json" ]; then
        local tmp="$out/comps/$id.json.tmp"
        jq --arg d "$(date +%F)" '.approved = true | .approved_on = $d' "$out/comps/$id.json" >"$tmp"
        mv "$tmp" "$out/comps/$id.json"
    fi
    cat >"$out/decision.md" <<EOF
# Design direction decision

pick: $id
label: $label
date: $(date +%F)
comp: $( [ -f "$out/comps/$id.png" ] && echo "comps/$id.png" || echo "none (wireframe card)" )
EOF
    echo "pick: $id ($label)"
}

main() {
    local step="${1:-help}"
    case "$step" in
        help|-h|--help) usage; return 0 ;;
    esac
    [ "$#" -ge 3 ] || { usage >&2; exit 64; }
    shift
    local dir out
    dir="$(cd "$1" && pwd -P)"; out="$2"; shift 2
    mkdir -p "$out"; out="$(cd "$out" && pwd -P)"
    case "$step" in
        context) step_context "$dir" "$out" ;;
        seed) step_seed "$dir" "$out" ;;
        cost) step_cost "$dir" "$out" ;;
        comps) step_comps "$dir" "$out" ;;
        pick) step_pick "$dir" "$out" "$@" ;;
        *) usage >&2; exit 64 ;;
    esac
}

main "$@"
