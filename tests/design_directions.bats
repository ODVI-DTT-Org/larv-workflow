#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    STUB_DIR="$(mktemp -d)"; export STUB_DIR
    export HOME="$STUB_DIR/home"; mkdir -p "$HOME"
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export LARV_HIGGSFIELD_BIN="$PROJECT_ROOT/tests/fixtures/higgsfield-stub.sh"
    export LARV_IMPECCABLE_SKILL_DIR="$PROJECT_ROOT/tests/fixtures/impeccable-launcher-stub"
    export LARV_HIGGSFIELD_ALLOW_FILE_URL=1
    OUT="$TMP/docs/larv/redesigns/t-impeccable-higgsfield/directions"
    mkdir -p "$OUT/prompts"
    printf '# PRS\n\nPouch receiving.\n' >"$TMP/PRODUCT.md"
}

teardown() {
    teardown_tmp_project "$TMP"
    rm -rf "$STUB_DIR"
}

write_options() {
    cat >"$OUT/options.json" <<'EOF'
{"title":"PRS directions","question":"Pick one","options":[
 {"id":"assigned","label":"Service counter","kicker":"THE ROLL","thesis":"Queue beside record","palette":["#ffffff","#125c3b"],"viewport":"Queue left, record right","risk":"Busy on desktop"},
 {"id":"model-pick","label":"Dispatch register","kicker":"IMPECCABLE'S PICK","thesis":"Fast register","palette":["#f4f7f5","#125c3b"],"viewport":"Wide table","risk":"Familiar"},
 {"id":"phone-card","label":"Pocket queue","thesis":"Phone first","palette":["#ffffff","#23392e"],"viewport":"One card per package","risk":"Dense on desktop","surface":"phone"},
 {"id":"cassette","label":"Control panel","verdict":"declined","thesis":"Panels","palette":["#ffffff"],"viewport":"Fascia","risk":"Misleading toggles","kept":"Clear group labels"}
]}
EOF
    for id in assigned model-pick phone-card; do printf 'Mockup %s\n' "$id" >"$OUT/prompts/$id.txt"; done
}

# write_options + a priced round (cost.json), so comps may spend
priced() {
    write_options
    bash scripts/design-directions.sh cost "$TMP" "$OUT" >/dev/null
}

@test "context keeps an existing PRODUCT.md" {
    run bash scripts/design-directions.sh context "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "Pouch receiving" "$TMP/PRODUCT.md"
}

@test "context without PRODUCT.md or larv brief asks the agent to author it" {
    rm "$TMP/PRODUCT.md"
    run bash scripts/design-directions.sh context "$TMP" "$OUT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"NEEDS_PRODUCT_MD"* ]]
}

@test "seed saves concept-seed output" {
    run bash scripts/design-directions.sh seed "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "DEALT INDICES" "$OUT/seed.txt"
    [ ! -f "$OUT/fallback" ]
}

@test "seed failure records the fallback and still exits 0" {
    STUB_SEED_FAIL=1 run bash scripts/design-directions.sh seed "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -qx "seed-unavailable" "$OUT/fallback"
}

@test "seed runs a non-executable launcher" {
    cp -r "$PROJECT_ROOT/tests/fixtures/impeccable-launcher-stub" "$STUB_DIR/skill"
    chmod -x "$STUB_DIR/skill/scripts/impeccable"
    LARV_IMPECCABLE_SKILL_DIR="$STUB_DIR/skill" run bash scripts/design-directions.sh seed "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "DEALT INDICES" "$OUT/seed.txt"
    [ ! -f "$OUT/fallback" ]
}

@test "cost fails clearly when hf_cost fails while signed in" {
    write_options
    STUB_COST=abc run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"hf_cost failed for assigned"* ]]
    [ ! -f "$OUT/cost.json" ]
}

@test "cost prices only comp cards and writes cost.json" {
    write_options
    run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.total' "$OUT/cost.json")" = "6" ]
    [ "$(jq -r '.per_comp | keys | join(",")' "$OUT/cost.json")" = "assigned,model-pick,phone-card" ]
    ! grep -q "cassette" "$OUT/cost.json"
}

@test "cost over the cap exits 4 unless the spend was confirmed" {
    write_options
    LARV_HIGGSFIELD_CREDIT_CAP=5 run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 4 ]
    [[ "$output" == *"6 credits exceeds cap 5"* ]]
    LARV_HIGGSFIELD_CREDIT_CAP=5 LARV_DESIGN_CONFIRMED_SPEND=6 run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
}

@test "comps writes png and sidecar for each comp card with the right aspect" {
    priced
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    for id in assigned model-pick phone-card; do
        [ -s "$OUT/comps/$id.png" ]
        [ "$(jq -r '.model' "$OUT/comps/$id.json")" = "nano_banana_pro" ]
        [ "$(jq -r '.approved' "$OUT/comps/$id.json")" = "false" ]
        [ "$(jq -r '.sample_data' "$OUT/comps/$id.json")" = "true" ]
    done
    [ ! -e "$OUT/comps/cassette.png" ]
    [ "$(jq -r '.aspect_ratio' "$OUT/comps/phone-card.json")" = "9:16" ]
    [ "$(jq -r '.aspect_ratio' "$OUT/comps/assigned.json")" = "3:2" ]
}

@test "comps falls back per card when Higgsfield fails" {
    priced
    STUB_FAIL_CREATE=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/assigned.fallback" ]
    [ ! -e "$OUT/comps/assigned.png" ]
}

@test "comps falls back for every card when signed out, without calling create" {
    write_options
    STUB_SIGNED_OUT=1 bash scripts/design-directions.sh cost "$TMP" "$OUT"
    STUB_SIGNED_OUT=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/model-pick.fallback" ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps skips existing images so a rerun spends nothing" {
    priced
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    : >"$STUB_DIR/hf.log"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps refuses reference images without the fictional-data confirmation" {
    priced
    mkdir -p "$OUT/refs"; printf 'png' >"$OUT/refs/reference.png"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 5 ]
    [[ "$output" == *"FICTIONAL-DATA-CONFIRMED"* ]]
    touch "$OUT/refs/FICTIONAL-DATA-CONFIRMED"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q -- "--image-references $OUT/refs/reference.png" "$STUB_DIR/hf.log"
}

@test "pick approves only the chosen sidecar and writes decision.md" {
    priced
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" model-pick
    [ "$status" -eq 0 ]
    [ "$(jq -r '.approved' "$OUT/comps/model-pick.json")" = "true" ]
    [ "$(jq -r '.approved' "$OUT/comps/assigned.json")" = "false" ]
    grep -q "pick: model-pick" "$OUT/decision.md"
    grep -q "Dispatch register" "$OUT/decision.md"
}

@test "pick rejects an unknown id" {
    write_options
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" nope
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown option id: nope"* ]]
}

@test "board renders every card with comps, sample-data labels and no external URLs" {
    priced
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    html="$OUT/board/index.html"
    for label in "Service counter" "Dispatch register" "Pocket queue" "Control panel"; do grep -q "$label" "$html"; done
    grep -q 'src="comps/assigned.png"' "$html"
    [ -s "$OUT/board/comps/assigned.png" ]
    grep -q "Sample data" "$html"
    grep -q "pick: assigned" "$html"
    grep -q "Clear group labels" "$html"
    ! grep -Eq '(src|href)="https?://' "$html"
}

@test "board renders a wireframe when a comp is missing and names the reason" {
    write_options
    STUB_SIGNED_OUT=1 bash scripts/design-directions.sh cost "$TMP" "$OUT"
    STUB_SIGNED_OUT=1 bash scripts/design-directions.sh comps "$TMP" "$OUT"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q 'class="wireframe"' "$OUT/board/index.html"
    grep -q "Higgsfield was unavailable" "$OUT/board/index.html"
}

@test "board escapes HTML in agent-authored text" {
    write_options
    jq '.options[0].thesis = "<script>alert(1)</script> & more"' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    ! grep -q "<script>alert" "$OUT/board/index.html"
    grep -q "&lt;script&gt;" "$OUT/board/index.html"
}

@test "board refuses a card missing required fields" {
    write_options
    jq 'del(.options[1].thesis)' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"option model-pick missing thesis"* ]]
}

@test "board refuses duplicate ids" {
    write_options
    jq '.options[1].id = "assigned"' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"duplicate option id: assigned"* ]]
}

@test "serve without STATE uses the basename slug, public host and run.yaml" {
    write_options
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    export LARV_VM_HOST=203.0.113.10 LARV_DESIGN_SKIP_PROBE=1
    export LARV_PORT_RESERVATION_DIR="$STUB_DIR/ports" LARV_SANDBOX_PROCESS_DIR="$STUB_DIR/procs"
    run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 0 ]
    url="$(cat "$OUT/board-url.txt")"
    [[ "$url" =~ ^http://203\.0\.113\.10:9[0-4][0-9][0-9]/$ ]]
    port="${url##*:}"; port="${port%/}"
    grep -q "board_port: $port" "$OUT/../run.yaml"
    curl -fsS "http://127.0.0.1:$port/" | grep -q "Dispatch register"
    run bash scripts/design-directions.sh stop "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"stopped larv-design-board-"* ]]
    [ ! -f "$STUB_DIR/procs/$(yq -r '.board_session' "$OUT/../run.yaml").pid" ]
    ! curl -fsS --max-time 1 "http://127.0.0.1:$port/" >/dev/null 2>&1
}

@test "serve refuses to announce a placeholder host" {
    write_options
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    mkdir -p "$STUB_DIR/bin"; printf '#!/bin/sh\necho ""\n' >"$STUB_DIR/bin/hostname"; chmod +x "$STUB_DIR/bin/hostname"
    PATH="$STUB_DIR/bin:$PATH" LARV_VM_HOST=sandbox.example.com run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 1 ]
    [[ "$output" == *"no public host"* ]]
    [ ! -f "$OUT/board-url.txt" ]
}

@test "serve stops the server and releases the port when probe-before-announce fails" {
    write_options
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    export LARV_VM_HOST=203.0.113.10 LARV_DESIGN_SKIP_FIREWALL=1 LARV_DESIGN_FORCE_PROBE_FAIL=1
    export LARV_PORT_RESERVATION_DIR="$STUB_DIR/ports" LARV_SANDBOX_PROCESS_DIR="$STUB_DIR/procs"
    run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 1 ]
    [ ! -f "$OUT/board-url.txt" ]
    source scripts/lib/design_tools.sh
    slug="$(design_slug "$TMP")"
    session="larv-design-board-$slug"
    log="$STUB_DIR/procs/$session.log"
    [ -f "$log" ]
    port="$(grep -oE ':[0-9]{4}\)? ' "$log" | head -1 | grep -oE '[0-9]{4}')"
    [ -n "$port" ]
    [ ! -f "$STUB_DIR/procs/$session.pid" ]
    ! curl -fsS --max-time 1 "http://127.0.0.1:$port/" >/dev/null 2>&1
    [ ! -f "$STUB_DIR/ports/mockup/$port" ]
}

@test "context delegates to impeccable.sh when only the larv product brief exists" {
    rm "$TMP/PRODUCT.md"
    mkdir -p "$TMP/docs/larv/00-discuss"
    printf '# Product brief\n\nPouch receiving service for a mailroom.\n' >"$TMP/docs/larv/00-discuss/product-brief.md"
    run bash scripts/design-directions.sh context "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$TMP/PRODUCT.md" ]
    [ ! -f "$TMP/DESIGN.md" ]
}

@test "comps refuses to spend without cost.json" {
    write_options
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 4 ]
    [[ "$output" == *"run cost first"* ]]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps refuses a cost.json that does not cover exactly the cards to generate" {
    priced
    printf 'Mockup changed\n' >"$OUT/prompts/assigned.txt"
    jq '.per_comp |= del(.["model-pick"]) | .total = 4' "$OUT/cost.json" >"$OUT/c.json" && mv "$OUT/c.json" "$OUT/cost.json"
    : >"$STUB_DIR/hf.log"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 4 ]
    [[ "$output" == *"does not match"* ]]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps refuses a cost.json over the cap without confirmed spend" {
    write_options
    LARV_HIGGSFIELD_CREDIT_CAP=5 LARV_DESIGN_CONFIRMED_SPEND=6 bash scripts/design-directions.sh cost "$TMP" "$OUT"
    LARV_HIGGSFIELD_CREDIT_CAP=5 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 4 ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
    LARV_HIGGSFIELD_CREDIT_CAP=5 LARV_DESIGN_CONFIRMED_SPEND=6 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "cost --only prices one card and records only" {
    write_options
    run bash scripts/design-directions.sh cost "$TMP" "$OUT" --only assigned
    [ "$status" -eq 0 ]
    [ "$(jq -r '.total' "$OUT/cost.json")" = "2" ]
    [ "$(jq -r '.per_comp | keys | join(",")' "$OUT/cost.json")" = "assigned" ]
    [ "$(jq -c '.only' "$OUT/cost.json")" = '["assigned"]' ]
}

@test "cost --only rejects an unknown or declined id" {
    write_options
    run bash scripts/design-directions.sh cost "$TMP" "$OUT" --only nope
    [ "$status" -eq 64 ]
    [[ "$output" == *"--only: unknown or declined option id: nope"* ]]
    run bash scripts/design-directions.sh cost "$TMP" "$OUT" --only cassette
    [ "$status" -eq 64 ]
    [[ "$output" == *"--only: unknown or declined option id: cassette"* ]]
}

@test "cost without --only has no only key (unchanged behaviour)" {
    write_options
    run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r 'has("only")' "$OUT/cost.json")" = "false" ]
}

@test "comps uses cost.json's only selection and wireframes the rest" {
    write_options
    bash scripts/design-directions.sh cost "$TMP" "$OUT" --only assigned >/dev/null
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -s "$OUT/comps/assigned.png" ]
    [ "$(grep -c "generate create" "$STUB_DIR/hf.log")" = "1" ]
    [ ! -e "$OUT/comps/model-pick.png" ]
    [ "$(cat "$OUT/comps/model-pick.fallback")" = "not-selected" ]
    [ "$(cat "$OUT/comps/phone-card.fallback")" = "not-selected" ]
    [[ "$output" == *"comps: model-pick -> wireframe card (not-selected)"* ]]
}

@test "comps --only must match cost.json's only" {
    write_options
    bash scripts/design-directions.sh cost "$TMP" "$OUT" --only assigned >/dev/null
    run bash scripts/design-directions.sh comps "$TMP" "$OUT" --only model-pick
    [ "$status" -eq 4 ]
    [[ "$output" == *"comps: --only does not match cost.json (rerun cost)"* ]]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps --only matching cost.json's only succeeds" {
    write_options
    bash scripts/design-directions.sh cost "$TMP" "$OUT" --only assigned >/dev/null
    run bash scripts/design-directions.sh comps "$TMP" "$OUT" --only assigned
    [ "$status" -eq 0 ]
    [ -s "$OUT/comps/assigned.png" ]
}

@test "board shows the credit-limit note when a card is not-selected" {
    write_options
    bash scripts/design-directions.sh cost "$TMP" "$OUT" --only assigned >/dev/null
    bash scripts/design-directions.sh comps "$TMP" "$OUT" >/dev/null
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -q "Some cards are shown as wireframes to keep this round within its credit limit." "$OUT/board/index.html"
}

@test "cost and comps behave unchanged without --only" {
    priced
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    for id in assigned model-pick phone-card; do [ -s "$OUT/comps/$id.png" ]; done
}

@test "cost and comps reject a non-numeric cap" {
    write_options
    LARV_HIGGSFIELD_CREDIT_CAP="10 credits" run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"must be a whole number"* ]]
    [ ! -f "$OUT/cost.json" ]
    bash scripts/design-directions.sh cost "$TMP" "$OUT"
    LARV_DESIGN_CONFIRMED_SPEND=lots run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "cost writes a zero-credit fallback when the Higgsfield binary is missing" {
    write_options
    LARV_HIGGSFIELD_BIN=/nonexistent run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -c '.' "$OUT/cost.json")" = '{"per_comp":{},"total":0,"cap":10,"fallback":"higgsfield-unavailable"}' ]
    LARV_HIGGSFIELD_BIN=/nonexistent run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -qx "higgsfield-unavailable" "$OUT/comps/assigned.fallback"
}

@test "cost writes a zero-credit fallback when Higgsfield is signed out" {
    write_options
    STUB_SIGNED_OUT=1 run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.fallback' "$OUT/cost.json")" = "higgsfield-unavailable" ]
    [ "$(jq -r '.total' "$OUT/cost.json")" = "0" ]
}

@test "comps falls back with low-credits when the balance is below the round total" {
    priced
    STUB_CREDITS=5 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    grep -qx "low-credits" "$OUT/comps/assigned.fallback"
    ! grep -q "generate create" "$STUB_DIR/hf.log"
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    grep -q "credits ran low" "$OUT/board/index.html"
    grep -q 'class="wireframe' "$OUT/board/index.html"
}

@test "comps sidecar records credits and prints the balance before and after" {
    priced
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.credits' "$OUT/comps/assigned.json")" = "2" ]
    [[ "$output" == *"balance before: 79 credits"* ]]
    [[ "$output" == *"balance after: 79 credits"* ]]
}

@test "a changed prompt is re-priced and regenerated; the board drops stale copies" {
    priced
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    printf 'Mockup assigned, rerolled\n' >"$OUT/prompts/assigned.txt"
    run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.per_comp | keys | join(",")' "$OUT/cost.json")" = "assigned" ]
    STUB_FAIL_CREATE=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/assigned.fallback" ]
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ ! -e "$OUT/board/comps/assigned.png" ]
    ! grep -q 'src="comps/assigned.png"' "$OUT/board/index.html"
    [ -e "$OUT/board/comps/model-pick.png" ]
    : >"$STUB_DIR/hf.log"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ "$(grep -c "generate create" "$STUB_DIR/hf.log")" = "1" ]
    grep -q "rerolled" "$OUT/comps/assigned.json"
}

@test "seed passes --from and --reroll through to concept-seed" {
    run bash scripts/design-directions.sh seed "$TMP" "$OUT" --from stubkey1 --reroll 2
    [ "$status" -eq 0 ]
    grep -q -- "concept-seed --candidate-count 7 --from stubkey1 --reroll 2" "$STUB_DIR/impeccable.log"
    run bash scripts/design-directions.sh seed "$TMP" "$OUT" --reroll x
    [ "$status" -ne 0 ]
    run bash scripts/design-directions.sh seed "$TMP" "$OUT" --from stubkey1
    [ "$status" -ne 0 ]
}

@test "pick accepts the canon card" {
    write_options
    jq '.canonCard = {"label":"Category standard","thesis":"Plain CRM","palette":["#ffffff"],"viewport":"Table","risk":"Familiar"}' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    grep -q "pick: canon" "$OUT/board/index.html"
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" canon
    [ "$status" -eq 0 ]
    grep -q "pick: canon" "$OUT/decision.md"
    grep -q "Category standard" "$OUT/decision.md"
}

@test "pick rejects a declined option" {
    write_options
    run bash scripts/design-directions.sh pick "$TMP" "$OUT" cassette
    [ "$status" -ne 0 ]
    [[ "$output" == *"declined"* ]]
    [ ! -f "$OUT/decision.md" ]
}

@test "board and comps reject unsafe option ids" {
    write_options
    jq '.options[0].id = "../evil"' "$OUT/options.json" >"$OUT/o.json" && mv "$OUT/o.json" "$OUT/options.json"
    run bash scripts/design-directions.sh board "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid option id: ../evil"* ]]
    run bash scripts/design-directions.sh cost "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid option id: ../evil"* ]]
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid option id: ../evil"* ]]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "serve records design-board-port by default and honors LARV_DESIGN_PORT_KIND" {
    write_options
    bash scripts/state.sh init "$TMP" prs greenfield >/dev/null
    bash scripts/design-directions.sh board "$TMP" "$OUT"
    export LARV_VM_HOST=203.0.113.10 LARV_DESIGN_SKIP_PROBE=1
    export LARV_PORT_RESERVATION_DIR="$STUB_DIR/ports" LARV_SANDBOX_PROCESS_DIR="$STUB_DIR/procs"
    run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 0 ]
    [ "$(yq -r '[.execution.allocations[] | select(.kind == "design-board-port")] | length' "$TMP/docs/larv/STATE.yaml")" = "1" ]
    [ "$(yq -r '[.execution.allocations[] | select(.kind == "mockup-port")] | length' "$TMP/docs/larv/STATE.yaml")" = "0" ]
    bash scripts/design-directions.sh stop "$TMP" "$OUT"
    LARV_DESIGN_PORT_KIND=mockup-port run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -eq 0 ]
    [ "$(yq -r '[.execution.allocations[] | select(.kind == "mockup-port")] | length' "$TMP/docs/larv/STATE.yaml")" = "1" ]
    run bash scripts/design-directions.sh stop "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    LARV_DESIGN_PORT_KIND=bogus run bash scripts/design-directions.sh serve "$TMP" "$OUT" auto
    [ "$status" -ne 0 ]
    [[ "$output" == *"LARV_DESIGN_PORT_KIND"* ]]
}

@test "stop is a no-op success when no board is running" {
    write_options
    export LARV_SANDBOX_PROCESS_DIR="$STUB_DIR/procs" LARV_PORT_RESERVATION_DIR="$STUB_DIR/ports"
    run bash scripts/design-directions.sh stop "$TMP" "$OUT"
    [ "$status" -eq 0 ]
}
