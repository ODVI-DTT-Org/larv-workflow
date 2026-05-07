#!/usr/bin/env bats

load helpers

setup() {
    REPO="$(mktemp -d)"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "test"
    mkdir -p "$REPO/docs/larv/01-domain" "$REPO/docs/larv/02-architecture" \
        "$REPO/docs/larv/03-design" "$REPO/docs/larv/06-implementation" \
        "$REPO/adr"
    bash scripts/state.sh init "$REPO" todo-app greenfield

    cp tests/fixtures/integration-greenfield/elephant-carpaccio.md \
       "$REPO/docs/larv/06-implementation/elephant-carpaccio.md"
    cp tests/fixtures/integration-greenfield/decisions.md \
       "$REPO/docs/larv/decisions.md"

    printf "# C4 Context\n\nMermaid here.\n" > "$REPO/docs/larv/02-architecture/c4-context.md"
    echo "# Domain model" > "$REPO/docs/larv/01-domain/domain-model.md"

    git -C "$REPO" add . && git -C "$REPO" commit -q -m "fixtures"
}

teardown() { [ -d "$REPO" ] && rm -rf "$REPO"; }

@test "integration: end-to-end handsoff + tracker + starting-points" {
    cd "$REPO"

    bash -c '
        . '"$PROJECT_ROOT"'/scripts/lib/vm.sh
        . '"$PROJECT_ROOT"'/scripts/lib/handsoff.sh
        . '"$PROJECT_ROOT"'/scripts/lib/tracker.sh
        . '"$PROJECT_ROOT"'/scripts/lib/git_safe.sh

        tracker_init "."
        tracker_render "."
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." app-port 8001
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." mockup-port 9001
        bash '"$PROJECT_ROOT"'/scripts/state.sh record-allocation "." db-name larv_todo_app_2026_05

        handsoff_render_index "."
        handsoff_render_bootstrap_sandbox "."
        handsoff_render_runtime_guides "."
        handsoff_render_slice "." slice-01 auth-scaffold
        handsoff_render_slice "." slice-02 todos-crud
        handsoff_render_starting_points "."
    '

    [ -f docs/Handsoff.md ]
    [ -f docs/Handsoff/bootstrap-sandbox.md ]
    [ -f docs/Handsoff/production-deploy.md ]
    [ -f docs/Handsoff/env-guide.md ]
    [ -f docs/Handsoff/operations-guide.md ]
    [ -f docs/Handsoff/package-guide.md ]
    [ -f docs/Handsoff/slice-01-auth-scaffold.md ]
    [ -f docs/Handsoff/slice-02-todos-crud.md ]
    [ -f CLAUDE.md ]
    [ -f AGENTS.md ]
    [ -f GEMINI.md ]
    [ -f .cursor/rules/larv.mdc ]
    [ -f .codex/AGENTS.md ]
    [ -f docs/larv/implementation-tracker.yaml ]

    grep -q "31.220.79.31" docs/Handsoff.md
    grep -q "9001" docs/Handsoff.md
    ! grep -q "8001" docs/Handsoff.md
    ! grep -q "larv_todo_app_2026_05" docs/Handsoff.md
    grep -q "8000 8999" docs/Handsoff/bootstrap-sandbox.md

    # Spec discipline §3.2 — handsoff is self-contained
    ! grep -rE 'scripts/(lib/)?(state|lock|tracker|handsoff|verifier|probe|gate|git_safe)\.sh' \
        docs/Handsoff.md docs/Handsoff/

    # Spec discipline §15.2 — Handsoff includes inlined sections
    grep -q "Handsoff — todo-app" docs/Handsoff.md
    grep -q "Sandbox Bootstrap" docs/Handsoff.md
    grep -q "bootstrap-sandbox.md" docs/Handsoff.md
    grep -q "production-deploy.md" docs/Handsoff.md
    grep -q "env-guide.md" docs/Handsoff.md
    grep -q "operations-guide.md" docs/Handsoff.md
    grep -q "package-guide.md" docs/Handsoff.md
    grep -q "Bootstrap Sandbox" docs/Handsoff/bootstrap-sandbox.md
    grep -q "Laravel Cloud" docs/Handsoff/production-deploy.md
    grep -q "Namecheap" docs/Handsoff/production-deploy.md
    grep -q "cd $REPO" docs/Handsoff/slice-01-auth-scaffold.md

    # Starting-point files all reference Handsoff.md
    grep -q "Handsoff.md" CLAUDE.md
    grep -q "bootstrap-sandbox.md" CLAUDE.md
    grep -q "production-deploy.md" CLAUDE.md
    grep -q "package-guide.md" CLAUDE.md
    grep -q "Handsoff.md" AGENTS.md
    grep -q "Handsoff.md" GEMINI.md
    grep -q "Handsoff.md" .cursor/rules/larv.mdc
    grep -q "Handsoff.md" .codex/AGENTS.md
}

@test "integration: routing menu sets STATE.yaml.execution.mode" {
    cd "$REPO"
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/gate.sh
        echo subagents | routing_menu '.'
    "
    [ "$status" -eq 0 ]
    run yq -r '.execution.mode' docs/larv/STATE.yaml
    [ "$output" = "executing-subagents" ]
}

@test "integration: safe_commit_docs commits only docs/ and adr/" {
    cd "$REPO"
    echo "non-docs change" > app.php
    mkdir -p docs/larv/00-discuss
    echo "doc change" > docs/larv/00-discuss/product-brief.md
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/git_safe.sh
        safe_commit_docs 'msg'
    "
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "dirty path"

    rm app.php
    run bash -c "
        . '$PROJECT_ROOT'/scripts/lib/git_safe.sh
        safe_commit_docs 'msg'
    "
    [ "$status" -eq 0 ]
}
