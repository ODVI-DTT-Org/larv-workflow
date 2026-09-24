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

step_board() {
    local dir="$1" out="$2"
    [ -f "$out/options.json" ] || { echo "ERROR: $out/options.json missing" >&2; return 1; }
    mkdir -p "$out/board/comps"
    local id
    for id in $(comp_ids "$out"); do
        [ -f "$out/comps/$id.png" ] && cp "$out/comps/$id.png" "$out/board/comps/$id.png"
    done
    python3 - "$out" "$PLUGIN_ROOT/templates/design-board.html.tmpl" <<'PY'
import html, json, sys
from pathlib import Path
out = Path(sys.argv[1]); tmpl = Path(sys.argv[2]).read_text(encoding="utf-8")
data = json.loads((out / "options.json").read_text(encoding="utf-8"))
opts = list(data.get("options") or [])
canon = data.get("canonCard")
if isinstance(canon, dict):
    canon = dict(canon, id=canon.get("id") or "canon", kicker=canon.get("kicker") or "CATEGORY STANDARD")
    opts.append(canon)
seen = set()
for o in opts:
    oid = o.get("id")
    if not oid:
        sys.exit("ERROR: option without id")
    if oid in seen:
        sys.exit(f"ERROR: duplicate option id: {oid}")
    seen.add(oid)
    for field in ("label", "thesis", "palette", "viewport", "risk"):
        if not o.get(field):
            sys.exit(f"ERROR: option {oid} missing {field}")
e = lambda s: html.escape(str(s), quote=True)
fallback = (out / "fallback").read_text().strip() if (out / "fallback").exists() else ""
reasons = set()
cards, declined = [], []
for o in opts:
    oid = o["id"]
    chips = "".join(f'<span class="chip" style="background:{e(c)}" title="{e(c)}"></span>' for c in o["palette"][:6])
    if o.get("verdict") == "declined":
        kept = f' Kept: {e(o["kept"])}' if o.get("kept") else ""
        declined.append(f'<li><strong>{e(o["label"])}</strong> <span class="muted">— {e(o.get("case") or o["risk"])}.{kept}</span></li>')
        continue
    png = out / "board" / "comps" / f"{oid}.png"
    if png.exists():
        visual = f'<img src="comps/{e(oid)}.png" alt="{e(o["label"])} comp (sample data)" loading="lazy">'
    else:
        fb = out / "comps" / f"{oid}.fallback"
        reasons.add(fb.read_text().strip() if fb.exists() else "no-comp")
        pal = o["palette"] + ["#dddddd"] * 3
        phone = " phone" if o.get("surface") == "phone" else ""
        visual = (f'<div class="wireframe{phone}" aria-label="{e(o["label"])} wireframe" style="background:{e(pal[0])}">'
                  f'<span style="background:{e(pal[1])}"></span><span style="background:{e(pal[2])};opacity:.35"></span></div>')
    kicker = f'<div class="kicker">{e(o["kicker"])}</div>' if o.get("kicker") else ""
    cards.append(f'''<article class="card" id="{e(oid)}">{visual}<div class="body">{kicker}
<h2>{e(o["label"])}</h2><p>{e(o["thesis"])}</p><div class="chips">{chips}</div>
<p class="muted"><strong>First screen:</strong> {e(o["viewport"])}</p>
<p class="muted"><strong>Risk:</strong> {e(o["risk"])}</p>
<code class="pick">pick: {e(oid)}</code></div></article>''')
notes = []
if fallback == "seed-unavailable":
    notes.append("Impeccable's direction service was unreachable; these directions were written from PRODUCT.md.")
if reasons & {"higgsfield-unavailable", "generation-failed"}:
    notes.append("Higgsfield was unavailable for some cards, so they show zero-credit wireframes.")
note = f'<p class="note">{" ".join(e(n) for n in notes)}</p>' if notes else ""
dec = f'<section class="declined"><h3>Considered and declined</h3><ul>{"".join(declined)}</ul></section>' if declined else ""
page = (tmpl.replace("{{TITLE}}", e(data.get("title") or "Design directions"))
            .replace("{{QUESTION}}", e(data.get("question") or "Choose one direction."))
            .replace("{{NOTE}}", note).replace("{{CARDS}}", "\n".join(cards)).replace("{{DECLINED}}", dec))
(out / "board" / "index.html").write_text(page, encoding="utf-8")
print(f"board: {len(cards)} cards, {len(declined)} declined -> {out / 'board' / 'index.html'}")
PY
}

# step_serve_cleanup <session> <port> <slug>
# Stops any server the current serve attempt started and releases its port
# reservation. Safe to call even when the server never started (static_server_stop
# / release_port_reservation are no-ops when there is nothing to clean up).
step_serve_cleanup() {
    local session="$1" port="$2" slug="$3"
    static_server_stop "" "$session" || true
    release_port_reservation mockup "$port" "$slug" || true
}

step_serve() {
    local dir="$1" out="$2" requested="${3:-auto}" host slug port session url
    [ -f "$out/board/index.html" ] || { echo "ERROR: run board first" >&2; return 1; }
    host="$(design_public_host)" || { echo "ERROR: no public host (set LARV_VM_HOST); refusing to announce a local URL" >&2; return 1; }
    export LARV_VM_HOST="$host"
    . "$PLUGIN_ROOT/scripts/lib/vm.sh"
    . "$PLUGIN_ROOT/scripts/lib/verifier.sh"
    . "$PLUGIN_ROOT/scripts/lib/static_server.sh"
    . "$PLUGIN_ROOT/scripts/lib/probe.sh"
    slug="$(design_slug "$dir")"
    if [ "$requested" = "auto" ] || [ -z "$requested" ]; then
        port="$(allocate_port mockup "$slug")"
    else
        case "$requested" in *[!0-9]*) echo "ERROR: port must be numeric or auto" >&2; return 1 ;; esac
        [ "$requested" -ge 9000 ] && [ "$requested" -le 9499 ] || { echo "ERROR: port must be in 9000-9499" >&2; return 1; }
        verify_allocation "$requested" mockup "$slug" || { echo "ERROR: port $requested is taken" >&2; return 1; }
        port="$requested"
    fi
    session="larv-design-board-$slug"
    if [ "${LARV_DESIGN_SKIP_PROBE:-0}" != "1" ] && [ "${LARV_DESIGN_SKIP_FIREWALL:-0}" != "1" ]; then
        static_server_check_remote_deps "" || { step_serve_cleanup "$session" "$port" "$slug"; echo "ERROR: php/curl/ss/setsid missing" >&2; return 1; }
        static_server_open_firewall "" "$port" || { step_serve_cleanup "$session" "$port" "$slug"; return 1; }
    fi
    static_server_start "" "$port" "$out/board" "$session" || { step_serve_cleanup "$session" "$port" "$slug"; return 1; }
    url="$(static_server_url "$port")/"
    if [ "${LARV_DESIGN_SKIP_PROBE:-0}" != "1" ]; then
        if [ "${LARV_DESIGN_FORCE_PROBE_FAIL:-0}" = "1" ]; then
            # Test-only hook: forces the probe-before-announce path to fail
            # without needing a real unroutable network round trip, so the
            # cleanup-on-probe-failure test stays fast and network-free.
            step_serve_cleanup "$session" "$port" "$slug"
            echo "ERROR: inside probe failed (forced for test)" >&2
            return 1
        fi
        probe_url_inside "" "$port" static || { step_serve_cleanup "$session" "$port" "$slug"; echo "ERROR: inside probe failed" >&2; return 1; }
        probe_with_retries "$url" static || { step_serve_cleanup "$session" "$port" "$slug"; echo "ERROR: external probe failed for $url" >&2; return 1; }
    fi
    release_port_reservation mockup "$port" "$slug" || true
    if [ -f "$dir/docs/larv/STATE.yaml" ]; then
        bash "$PLUGIN_ROOT/scripts/state.sh" record-allocation "$dir" mockup-port "$port"
    else
        printf 'slug: %s\nboard_port: %s\nboard_session: %s\n' "$slug" "$port" "$session" >"$out/../run.yaml"
    fi
    printf '%s\n' "$url" >"$out/board-url.txt"
    echo "Design board ready at $url"
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
        board) step_board "$dir" "$out" ;;
        serve) step_serve "$dir" "$out" "$@" ;;
        pick) step_pick "$dir" "$out" "$@" ;;
        *) usage >&2; exit 64 ;;
    esac
}

main "$@"
