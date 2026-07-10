#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    BIN_DIR="$TMP/bin"
    mkdir -p "$BIN_DIR"
}

teardown() { teardown_tmp_project "$TMP"; }

write_headroom_policy() {
    local hash="$1"
    cat >"$TMP/token-optimizers.yaml" <<EOF
lean-ctx:
  approved_version: "0.0.0"
  source_url: "https://leanctx.com/"
  release: "disabled"
  sha256: "REJECTED"
  approved_path_prefixes:
    - "$BIN_DIR"
  safe_mode: "disabled"
headroom:
  approved_version: "4.5.6"
  source_url: "https://pypi.org/project/headroom-ai/"
  release: "v4.5.6"
  sha256: "$hash"
  approved_path_prefixes:
    - "$BIN_DIR"
  safe_mode: "direct-compression-only,no-wrap,no-proxy,no-docker-wrapper,no-learning,no-telemetry,workspace-bounded-state"
EOF
}

@test "headroom combo skill exists and documents Ponytail Headroom Caveman policy" {
    [ -f skills/larv-headroom/SKILL.md ]
    grep -q "Ponytail" skills/larv-headroom/SKILL.md
    grep -q "Headroom" skills/larv-headroom/SKILL.md
    grep -q "Caveman" skills/larv-headroom/SKILL.md
    grep -q "scripts/headroom-combo.sh status" skills/larv-headroom/SKILL.md
    grep -q "workspace-bounded" skills/larv-headroom/SKILL.md
    grep -q "Do not use proxy" skills/larv-headroom/SKILL.md
}

@test "headroom combo reports safe Headroom with workspace-bounded env" {
    cat >"$BIN_DIR/headroom" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version|-v) echo "headroom 4.5.6" ;;
  *) echo "headroom $*" ;;
esac
EOF
    chmod +x "$BIN_DIR/headroom"
    local hash
    hash="$(sha256sum "$BIN_DIR/headroom" | awk '{print $1}')"
    write_headroom_policy "$hash"

    run env LARV_TOKEN_OPTIMIZER_POLICY="$TMP/token-optimizers.yaml" LARV_HEADROOM_BIN="$BIN_DIR/headroom" bash scripts/headroom-combo.sh status "$TMP"

    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Ponytail: active"
    echo "$output" | grep -q "Headroom: safe"
    echo "$output" | grep -q "$TMP/docs/larv/headroom"
    echo "$output" | grep -q "Caveman:"
    echo "$output" | grep -q "Token measurement:"
}

@test "headroom combo falls back when Headroom is unsafe or unavailable" {
    run env LARV_TOKEN_OPTIMIZER_POLICY="$TMP/missing.yaml" bash scripts/headroom-combo.sh status "$TMP"

    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Headroom: fallback"
}

@test "token optimizer rejects Headroom workspace state outside project" {
    cat >"$BIN_DIR/headroom" <<'EOF'
#!/usr/bin/env bash
echo "headroom 4.5.6"
EOF
    chmod +x "$BIN_DIR/headroom"
    local hash
    hash="$(sha256sum "$BIN_DIR/headroom" | awk '{print $1}')"
    write_headroom_policy "$hash"

    run env LARV_TOKEN_OPTIMIZER_POLICY="$TMP/token-optimizers.yaml" LARV_TOKEN_OPTIMIZER_CANDIDATES=headroom LARV_HEADROOM_BIN="$BIN_DIR/headroom" HEADROOM_WORKSPACE_DIR="/tmp/headroom-outside" bash scripts/token-optimizer.sh status "$TMP"

    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Optimizer: none (fallback)"
    echo "$output" | grep -q "workspace outside project"
}

@test "larv workflow skills and command wrappers invoke the headroom combo bootstrap" {
    for skill in skills/larv-*/SKILL.md codex-skills/*/SKILL.md; do
        grep -q "headroom-combo.sh status" "$skill" || { echo "missing combo bootstrap in $skill"; return 1; }
        grep -q 'headroom-combo.sh status "$PWD"' "$skill" || { echo "combo bootstrap must pass project cwd in $skill"; return 1; }
    done

    for cmd in commands/larv-*.md; do
        grep -q "headroom-combo.sh status" "$cmd" || { echo "missing combo bootstrap in $cmd"; return 1; }
        grep -q 'headroom-combo.sh status "$PWD"' "$cmd" || { echo "combo bootstrap must pass project cwd in $cmd"; return 1; }
    done
}
