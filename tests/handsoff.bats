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
