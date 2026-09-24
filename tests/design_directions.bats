#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    STUB_DIR="$(mktemp -d)"; export STUB_DIR
    export HOME="$STUB_DIR/home"; mkdir -p "$HOME"
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export LARV_HIGGSFIELD_BIN="$PROJECT_ROOT/tests/fixtures/higgsfield-stub.sh"
    export LARV_IMPECCABLE_SKILL_DIR="$PROJECT_ROOT/tests/fixtures/impeccable-launcher-stub"
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

@test "cost fails clearly when hf_cost fails" {
    write_options
    LARV_HIGGSFIELD_BIN=/nonexistent run bash scripts/design-directions.sh cost "$TMP" "$OUT"
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
    write_options
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
    write_options
    STUB_FAIL_CREATE=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/assigned.fallback" ]
    [ ! -e "$OUT/comps/assigned.png" ]
}

@test "comps falls back for every card when signed out, without calling create" {
    write_options
    STUB_SIGNED_OUT=1 run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    [ -f "$OUT/comps/model-pick.fallback" ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps skips existing images so a rerun spends nothing" {
    write_options
    bash scripts/design-directions.sh comps "$TMP" "$OUT"
    : >"$STUB_DIR/hf.log"
    run bash scripts/design-directions.sh comps "$TMP" "$OUT"
    [ "$status" -eq 0 ]
    ! grep -q "generate create" "$STUB_DIR/hf.log"
}

@test "comps refuses reference images without the fictional-data confirmation" {
    write_options
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
    write_options
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
    write_options
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
    source scripts/lib/vm.sh; source scripts/lib/static_server.sh
    static_server_stop "" "$(yq -r '.board_session' "$OUT/../run.yaml")"
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
