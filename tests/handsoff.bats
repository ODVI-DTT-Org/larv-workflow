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
    grep -q "No sandbox URL recorded yet" "$TMP/docs/Handsoff.md"
    grep -q "docs/larv/03-design/visual-implementation-contract.md" "$TMP/docs/Handsoff.md"
    grep -q "docs/larv/03-design/mockups/" "$TMP/docs/Handsoff.md"
    grep -q "Model selection starter prompt" "$TMP/docs/Handsoff.md"
    grep -q "use the user's preferred model" "$TMP/docs/Handsoff.md"
    grep -q "You are continuing a larv-managed Laravel implementation" "$TMP/docs/Handsoff.md"
    grep -q "Ponytail YAGNI audit" "$TMP/docs/Handsoff.md"
    grep -q "docs/larv/features/<feature-slug>/yagni-audit.md" "$TMP/docs/Handsoff.md"
    grep -q "before handoff generation" "$TMP/docs/Handsoff.md"
    grep -q "do not remove security, validation, accessibility, or explicitly requested scope" "$TMP/docs/Handsoff.md"
}

@test "handsoff_render_index inlines C4 content (does not link only)" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"
    grep -q "C4 Context" "$TMP/docs/Handsoff.md"
}

@test "missing source docs render explicit absence notices instead of TBD" {
    rm -f "$TMP/docs/larv/01-domain/domain-model.md" \
        "$TMP/docs/larv/02-architecture/c4-context.md" \
        "$TMP/docs/larv/03-design/data-model.md" \
        "$TMP/docs/larv/03-design/api-surface.md" \
        "$TMP/docs/larv/04-test-strategy/strategy.md"

    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP'"

    grep -q "No standalone source exists yet." "$TMP/docs/Handsoff.md"
    grep -q "Use feature docs, tracker, implementation reports, and source code as the recovery source." "$TMP/docs/Handsoff.md"
    grep -q "Do not invent missing product or architecture details." "$TMP/docs/Handsoff.md"
    ! grep -q "TBD" "$TMP/docs/Handsoff.md"
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
    grep -q "Seeded test credentials" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "normal login" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Do not add a navbar impersonation" "$TMP/docs/Handsoff/slice-01-auth.md"
    ! grep -q "User Switcher" "$TMP/docs/Handsoff/slice-01-auth.md"
    ! grep -q "DEMO_MODE" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-slice-01.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Visual implementation contract" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/03-design/visual-implementation-contract.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "interactive HTML Effectiveness prototypes" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "interaction-map.md" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "browser-click the same primary workflow paths" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "default Tailwind panels" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "visual source of truth" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "docs/larv/08-implementation/screenshots/slice-01/" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "approved deviations" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Browser flow and mockup parity verification" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Visit every app page" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Sign in with every seeded credential" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Compare each UI route to its chosen mockup" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Compare each UI workflow to its chosen mockup" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Browser flow verification" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Parity result: pass" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Source-code parity and single-layout contract" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "PRD/product brief" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "policy-app pattern" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "admin views should extend the same main layout" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Single-layout and Filament verification" "$TMP/docs/Handsoff/slice-01-auth.md"
    grep -q "Source-code parity" "$TMP/docs/Handsoff/slice-01-auth.md"
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

@test "handsoff_render_starting_points derives sandbox host from runtime URL before placeholder" {
    mkdir -p "$TMP/docs/larv/07-runtime"
    printf "http://46.250.229.188:25000/admin/snowflake\n" > "$TMP/docs/larv/07-runtime/sandbox-url.txt"

    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"

    grep -q "VM host | 46.250.229.188" "$TMP/AGENTS.md"
    grep -q "App URL | http://46.250.229.188:25000" "$TMP/AGENTS.md"
    grep -q "Do not SSH to \`46.250.229.188\`" "$TMP/.cursor/rules/larv.mdc"
    ! grep -q "sandbox.example.com" "$TMP/AGENTS.md"
    ! grep -q "sandbox.example.com" "$TMP/.cursor/rules/larv.mdc"
}

@test "handoff index and root AGENTS agree with sandbox runtime host" {
    mkdir -p "$TMP/docs/larv/07-runtime"
    printf "http://46.250.229.188:25000/admin/snowflake\n" > "$TMP/docs/larv/07-runtime/sandbox-url.txt"

    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP' && handsoff_render_starting_points '$TMP'"

    grep -q "VM host | 46.250.229.188" "$TMP/docs/Handsoff.md"
    grep -q "App URL | http://46.250.229.188:25000" "$TMP/docs/Handsoff.md"
    grep -q "VM host | 46.250.229.188" "$TMP/AGENTS.md"
    grep -q "App URL | http://46.250.229.188:25000" "$TMP/AGENTS.md"
    ! grep -q "sandbox.example.com" "$TMP/docs/Handsoff.md"
    ! grep -q "sandbox.example.com" "$TMP/AGENTS.md"
}

@test "handsoff_render_starting_points derives sandbox host from STATE when runtime URL is absent" {
    yq -i '.sandbox.app_url = "http://198.51.100.24:25000/"' "$TMP/docs/larv/STATE.yaml"

    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"

    grep -q "VM host | 198.51.100.24" "$TMP/AGENTS.md"
    grep -q "App URL | http://198.51.100.24:25000" "$TMP/AGENTS.md"
    ! grep -q "sandbox.example.com" "$TMP/AGENTS.md"
}

@test "handsoff_render_starting_points derives sandbox host from env when runtime and STATE URLs are absent" {
    yq -i 'del(.sandbox.app_url)' "$TMP/docs/larv/STATE.yaml"
    printf "APP_URL=http://203.0.113.77:25000\n" > "$TMP/.env"

    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"

    grep -q "VM host | 203.0.113.77" "$TMP/AGENTS.md"
    grep -q "App URL | http://203.0.113.77:25000" "$TMP/AGENTS.md"
    ! grep -q "sandbox.example.com" "$TMP/AGENTS.md"
}

@test "handsoff_render_starting_points does not create nested AGENTS files" {
    mkdir -p "$TMP/app" "$TMP/resources" "$TMP/tests"
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    [ ! -e "$TMP/app/AGENTS.md" ]
    [ ! -e "$TMP/resources/AGENTS.md" ]
    [ ! -e "$TMP/tests/AGENTS.md" ]
    [ ! -e "$TMP/docs/larv/AGENTS.md" ]
    [ ! -e "$TMP/docs/Handsoff/AGENTS.md" ]
}

@test "starting-point files all reference docs/Handsoff.md" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        grep -q "Handsoff.md" "$f" || { echo "missing reference in $f"; return 1; }
    done
}

@test "generated handoff and starting-point files include Ponytail audit contract" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_index '$TMP' && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/docs/Handsoff.md"; do
        grep -q "Ponytail YAGNI audit" "$f" || { echo "missing Ponytail audit in $f"; return 1; }
        grep -q "docs/larv/features/<feature-slug>/yagni-audit.md" "$f" || { echo "missing audit path in $f"; return 1; }
        grep -q "before handoff generation" "$f" || { echo "missing pre-handoff refresh in $f"; return 1; }
        grep -q "need/not-needed decision" "$f" || { echo "missing need decision in $f"; return 1; }
        grep -q "removed scope" "$f" || { echo "missing removed scope in $f"; return 1; }
        grep -q "reused existing screens/config/workflows" "$f" || { echo "missing reuse record in $f"; return 1; }
        grep -q "rejected packages or abstractions" "$f" || { echo "missing rejected packages in $f"; return 1; }
        grep -q "slice-count rationale" "$f" || { echo "missing slice-count rationale in $f"; return 1; }
        grep -q "protected items not simplified away" "$f" || { echo "missing protected items in $f"; return 1; }
        grep -q "do not remove security, validation, accessibility, or explicitly requested scope" "$f" || { echo "missing protected scope rule in $f"; return 1; }
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
    grep -q "PostgreSQL-only" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'DB_CONNECTION="${DB_CONNECTION:-pgsql}"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "createdb" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "DB_HOST" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    ! grep -qi "mariadb" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    ! grep -qi "mysql" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "Sandbox ready at" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'PROJECT_ROOT="$(pwd -P)"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'APP_ROOT="$PROJECT_ROOT"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'APP_SESSION="larv-app-$SLUG-$APP_PORT"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'APP_PID_FILE="${LARV_SANDBOX_PROCESS_DIR:-/tmp/larv-sandbox-processes}/$APP_SESSION.pid"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "ask the user which public VM app port" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "LARV_APP_PORT" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q 'LARV_PROJECT_SLUG="$SLUG" LARV_APP_SESSION="$APP_SESSION" LARV_APP_PID_FILE="$APP_PID_FILE"' "$TMP/docs/Handsoff/bootstrap-sandbox.md"
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
    grep -q "Test Credentials" "$TMP/docs/user-manual/seed-data.md"
    grep -q "normal login" "$TMP/docs/user-manual/seed-data.md"
    grep -q "Permissions Scope" "$TMP/docs/user-manual/seed-data.md"
    ! grep -q "User Switcher" "$TMP/docs/user-manual/seed-data.md"
    ! grep -q "DEMO_MODE" "$TMP/docs/user-manual/seed-data.md"
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

@test "starting-point files include DOX-inspired read and freshness contract" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        grep -Eq "Read before editing|Start Here" "$f" || { echo "missing read-before-editing section in $f"; return 1; }
        grep -Eq "Nearest contract wins|Nearest Contract Wins" "$f" || { echo "missing nearest-contract precedence in $f"; return 1; }
        grep -qi "freshness\|Only update local contracts" "$f" || { echo "missing doc freshness guidance in $f"; return 1; }
        grep -q "docs/Handsoff/slice-NN-<name>.md" "$f" || { echo "missing slice handoff route in $f"; return 1; }
        grep -q "docs/larv/features/<feature-slug>/" "$f" || { echo "missing feature route in $f"; return 1; }
        grep -q "docs/larv/09-verification/" "$f" || { echo "missing verification route in $f"; return 1; }
        grep -q "docs/larv/10-deploy/" "$f" || { echo "missing deploy route in $f"; return 1; }
        grep -q "Do not update docs for formatting-only" "$f" || { echo "missing no-op freshness rule in $f"; return 1; }
        grep -q "refactor-only" "$f" || { echo "missing refactor-only freshness rule in $f"; return 1; }
        grep -q "test-only" "$f" || { echo "missing test-only freshness rule in $f"; return 1; }
    done
}

@test "starting-point files remain concise routing contracts" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        [ "$(wc -l < "$f")" -le 85 ] || { echo "too long: $f"; return 1; }
        grep -q "Preserve unrelated user changes" "$f" || { echo "missing dirty-worktree safety: $f"; return 1; }
        grep -qi "regenerat" "$f" || { echo "missing regeneration guidance: $f"; return 1; }
    done
}

@test "starting-point files use tool-neutral model guidance and hotfix routing" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        grep -q "If all slices are complete and the user asks for a hotfix" "$f" || { echo "missing hotfix routing guidance in $f"; return 1; }
        grep -q "nearest affected slice" "$f" || { echo "missing nearest affected slice guidance in $f"; return 1; }
        grep -qi "regenerat" "$f" || { echo "missing regeneration guidance in $f"; return 1; }
        ! grep -q "Opus" "$f" || { echo "model-specific Opus leaked into $f"; return 1; }
        ! grep -q "Sonnet" "$f" || { echo "model-specific Sonnet leaked into $f"; return 1; }
        ! grep -q "Haiku" "$f" || { echo "model-specific Haiku leaked into $f"; return 1; }
    done
}

@test "handsoff_render_starting_points writes validated non-empty bodies" {
    bash -c "source $PROJECT_ROOT/scripts/lib/handsoff.sh && handsoff_render_starting_points '$TMP'"
    for f in "$TMP/CLAUDE.md" "$TMP/AGENTS.md" "$TMP/GEMINI.md" \
             "$TMP/.cursor/rules/larv.mdc" "$TMP/.codex/AGENTS.md"; do
        [ "$(wc -c < "$f")" -gt 500 ] || { echo "too small: $f"; return 1; }
        grep -q "docs/Handsoff.md" "$f" || { echo "missing handoff reference: $f"; return 1; }
        grep -q "bootstrap-sandbox.md" "$f" || { echo "missing bootstrap reference: $f"; return 1; }
        grep -Eq "Fresh Session Prompt|Starter prompt" "$f" || { echo "missing fresh session prompt: $f"; return 1; }
        grep -q "You are continuing a larv-managed Laravel implementation" "$f" || { echo "missing starter prompt: $f"; return 1; }
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
