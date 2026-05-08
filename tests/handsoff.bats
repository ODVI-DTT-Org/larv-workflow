#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    bash scripts/state.sh init "$TMP" my-app greenfield
    # seed minimal docs the renderer expects
    mkdir -p "$TMP/docs/larv/01-domain" "$TMP/docs/larv/02-architecture" \
        "$TMP/docs/larv/03-design" "$TMP/docs/larv/06-implementation" \
        "$TMP/adr"
    printf "# C4 Context\n\nMermaid here.\n" > "$TMP/docs/larv/02-architecture/c4-context.md"
    echo "# Domain model" > "$TMP/docs/larv/01-domain/domain-model.md"
    cat > "$TMP/docs/larv/06-implementation/elephant-carpaccio.md" <<EOF
# Slice Plan

## slice-01-auth
goal: Auth scaffold
depends_on: []
parallel: false
EOF
}

teardown() { teardown_tmp_project "$TMP"; }

@test "handsoff_render_index writes docs/Handsoff.md" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff.md" ]
    grep -q "Handsoff — my-app" "$TMP/docs/Handsoff.md"
    grep -q "31.220.79.31" "$TMP/docs/Handsoff.md"
    grep -q "docs/larv/03-design/visual-implementation-contract.md" "$TMP/docs/Handsoff.md"
    grep -q "docs/larv/03-design/mockups/" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_index inlines C4 content (does not link only)" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    grep -q "C4 Context" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_slice writes docs/Handsoff/slice-01-auth.md" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff/slice-01-auth.md" ]
    grep -q "slice-01" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Review Gate" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "auto-all" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "manual-slice" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/user-manual/testing/slice-01-auth.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/user-manual/seed-data.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "at least 10 realistic records" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "multiple focused seeder classes" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "DEMO_MODE=true" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "User Switcher" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "DEMO_MODE=false" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-slice-01.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Visual implementation contract" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/03-design/visual-implementation-contract.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "default Tailwind panels" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "visual source of truth" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/08-implementation/screenshots/slice-01/" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "approved deviations" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Apply Laravel runtime changes" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Do not ask the user to run migrations" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "php artisan migrate --force" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "php artisan db:seed --force" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "npm run build" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "deploy-sandbox.sh" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Sandbox ready" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Laravel runtime commands run by the AI" "$TMP/docs/Handsoff/slice-01-auth.md"
    ! grep -q "Write \`IMPLEMENTATION-REPORT-slice-01.md\` at the project root" "$TMP/docs/Handsoff/slice-01-auth.md"
}

@test "handsoff slice commands start in local app root" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    grep -q "cd $TMP" "$TMP/docs/Handsoff/slice-01-auth.md"
}

@test "handsoff_render_slice contains inline tracker append snippet" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    grep -q 'yq -i' "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q 'implementation-tracker.yaml' "$TMP/docs/Handsoff/slice-01-auth.md"
}

@test "handsoff_render_slice does not reference plugin internal scripts" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_slice '$TMP' 'slice-01' 'auth'"
    # spec discipline §3.2: handsoff is self-contained
    if grep -E 'scripts/(state|lock|tracker|handsoff|verifier|probe|gate|git_safe)\.sh' \
        "$TMP/docs/Handsoff/slice-01-auth.md"; then
        echo "FAIL: handsoff references plugin scripts" >&2
        return 1
    fi
}

@test "handsoff_render_starting_points writes all five starting-point files" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    [ -f "$TMP/CLAUDE.md" ]
    [ -f "$TMP/AGENTS.md" ]
    [ -f "$TMP/GEMINI.md" ]
    [ -f "$TMP/.cursor/rules/larv.mdc" ]
    [ -f "$TMP/.codex/AGENTS.md" ]
}

@test "starting-point files all reference docs/Handsoff.md" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        grep -q "Handsoff.md" "$f" || { echo "missing reference in $f"; return 1; }
    done
}

@test "handsoff_render_index preserves multi-line inlined files" {
    cat > "$TMP/docs/larv/01-domain/domain-model.md" <<'EOF'
# Domain model

- User
- Workspace
EOF
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    grep -q -- "- User" "$TMP/docs/Handsoff.md"
    grep -q -- "- Workspace" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_bootstrap_sandbox writes self-contained bootstrap" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_bootstrap_sandbox '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff/bootstrap-sandbox.md" ]
    grep -q "Bootstrap Sandbox" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "deploy-sandbox.sh" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "ensure_laravel_scaffold" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "composer create-project laravel/laravel" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "DB_CONNECTION" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "createdb" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "CREATE DATABASE" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "DB_HOST" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "Sandbox ready at" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'PROJECT_ROOT="$(pwd -P)"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'APP_ROOT="$PROJECT_ROOT"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q '"kind":"project-root","value": strenv(APP_ROOT)' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    ! grep -q 'rsync -a --delete' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    ! grep -E 'scripts/lib/[a-z_]+\.sh' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
}

@test "handsoff index explains greenfield scaffold before sandbox" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    grep -q "creates the bare Laravel scaffold first" "$TMP/docs/Handsoff.md"
    grep -q "docs-only greenfield" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_runtime_guides writes deploy env and ops guides" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_runtime_guides '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/Handsoff/production-deploy.md" ]
    [ -f "$TMP/docs/Handsoff/env-guide.md" ]
    [ -f "$TMP/docs/Handsoff/operations-guide.md" ]
    [ -f "$TMP/docs/Handsoff/package-guide.md" ]
    [ -f "$TMP/docs/user-manual/README.md" ]
    [ -f "$TMP/docs/user-manual/installation.md" ]
    [ -f "$TMP/docs/user-manual/environment.md" ]
    [ -f "$TMP/docs/user-manual/seed-data.md" ]
    [ -d "$TMP/docs/user-manual/testing" ]
    [ -d "$TMP/docs/larv/08-implementation/reports" ]
    [ -f "$TMP/DOCS.md" ]
    grep -q "Laravel Cloud" "$TMP/docs/Handsoff/production-deploy.md"
    grep -q "Namecheap" "$TMP/docs/Handsoff/production-deploy.md"
    grep -q "DB_DATABASE" "$TMP/docs/Handsoff/env-guide.md"
    grep -q "Install" "$TMP/docs/Handsoff/operations-guide.md"
    grep -q "Filament" "$TMP/docs/Handsoff/package-guide.md"
    grep -q "Per-slice testing guides" "$TMP/docs/user-manual/README.md"
    grep -q "migrate:fresh --seed" "$TMP/docs/user-manual/seed-data.md"
    grep -q "Required Seeder Policy" "$TMP/docs/user-manual/seed-data.md"
    grep -q "DEMO_MODE=true" "$TMP/docs/user-manual/seed-data.md"
    grep -q "User Switcher" "$TMP/docs/user-manual/seed-data.md"
    grep -q "DEMO_MODE=false" "$TMP/docs/user-manual/seed-data.md"
    grep -q "docs/larv/08-implementation/reports/" "$TMP/DOCS.md"
    grep -q "docs/user-manual/README.md" "$TMP/DOCS.md"
}

@test "starting-point files require bootstrap before slices" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    grep -q "bootstrap-sandbox.md" "$TMP/CLAUDE.md"
    grep -q "bare Laravel scaffold" "$TMP/CLAUDE.md"
    grep -q "bootstrap-sandbox.md" "$TMP/AGENTS.md"
    grep -q "bootstrap-sandbox.md" "$TMP/GEMINI.md"
    grep -q "bootstrap-sandbox.md" "$TMP/.cursor/rules/larv.mdc"
    grep -q "bootstrap-sandbox.md" "$TMP/.codex/AGENTS.md"
}

@test "handsoff_render_starting_points writes validated non-empty bodies" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        [ "$(wc -c < "$f")" -gt 500 ] || { echo "too small: $f"; return 1; }
        grep -q "docs/Handsoff.md" "$f" || { echo "missing handoff reference: $f"; return 1; }
        grep -q "bootstrap-sandbox.md" "$f" || { echo "missing bootstrap reference: $f"; return 1; }
    done
}

@test "handsoff_render_starting_points does not overwrite files when template is missing" {
    plugin_copy="$BATS_TEST_TMPDIR/plugin-copy"
    cp -R "$PROJECT_ROOT" "$plugin_copy"
    rm -f "$plugin_copy/templates/ai-starting-point.md.tmpl"
    printf "keep me\n" > "$TMP/CLAUDE.md"
    run bash -c "source $plugin_copy/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    [ "$status" -ne 0 ]
    [ "$(cat "$TMP/CLAUDE.md")" = "keep me" ]
}
