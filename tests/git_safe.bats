#!/usr/bin/env bats

load helpers

setup() {
    REPO="$(mktemp -d)"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "test"
    mkdir -p "$REPO/docs/larv" "$REPO/adr"
    echo "init" >"$REPO/README.md"
    git -C "$REPO" add README.md
    git -C "$REPO" commit -q -m "initial"
}

teardown() {
    [ -d "$REPO" ] && rm -rf "$REPO"
}

@test "git_default_branch detects main" {
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && git_default_branch"
    [ "$status" -eq 0 ]
    # could be 'main' or 'master' depending on git default
    [[ "$output" =~ ^(main|master)$ ]]
}

@test "git_dirty_outside_docs returns 0 when no dirty paths exist" {
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -eq 0 ]
}

@test "git_dirty_outside_docs returns 1 when dirty path is outside generated docs allowlist" {
    echo "dirty" > "$REPO/app.php"
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -ne 0 ]
}

@test "git_dirty_outside_docs returns 0 when only docs/ is dirty" {
    mkdir -p "$REPO/docs/larv"
    echo "dirty" > "$REPO/docs/larv/note.md"
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -eq 0 ]
}

@test "git_dirty_outside_docs returns 0 for generated root docs and AI starting points" {
    echo "docs index" > "$REPO/DOCS.md"
    echo "claude" > "$REPO/CLAUDE.md"
    mkdir -p "$REPO/.codex" "$REPO/.cursor/rules"
    echo "codex" > "$REPO/.codex/AGENTS.md"
    echo "cursor" > "$REPO/.cursor/rules/larv.mdc"
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && git_dirty_outside_docs"
    [ "$status" -eq 0 ]
}

@test "safe_commit_docs commits docs adr and generated entry points to default branch" {
    mkdir -p "$REPO/docs/larv"
    echo "doc" > "$REPO/docs/larv/note.md"
    echo "docs index" > "$REPO/DOCS.md"
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && safe_commit_docs '[larv] phase 0: discuss approved'"
    [ "$status" -eq 0 ]
    run git -C "$REPO" log -1 --pretty=%s
    [[ "$output" == *"phase 0: discuss approved"* ]]
    git -C "$REPO" ls-files | grep -q '^DOCS.md$'
}

@test "safe_commit_docs refuses to commit if dirty paths exist outside generated docs allowlist" {
    echo "dirty" > "$REPO/app.php"
    mkdir -p "$REPO/docs/larv"
    echo "doc" > "$REPO/docs/larv/note.md"
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && safe_commit_docs 'msg'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "dirty path"
}

@test "safe_commit_docs no-ops when no generated docs changes are staged or unstaged" {
    run bash -c "cd $REPO && source $PROJECT_ROOT/scripts/lib/git_safe.sh && safe_commit_docs 'msg'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "nothing to commit"
}
