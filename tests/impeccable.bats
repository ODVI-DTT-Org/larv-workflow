#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
    BIN_DIR="$(mktemp -d)"
}

teardown() {
    teardown_tmp_project "$TMP"
    [ -n "${BIN_DIR:-}" ] && [ -d "$BIN_DIR" ] && rm -rf "$BIN_DIR"
}

write_stub_impeccable() {
    local exit_code="${1:-2}"
    cat >"$BIN_DIR/impeccable" <<EOF
#!/usr/bin/env bash
if printf '%s' "\$*" | grep -q -- '--json'; then
    printf '%s\n' '{"findings":[{"id":"nested-cards","file":"resources/views/app.blade.php"}],"count":1}'
fi
echo "nested-cards resources/views/app.blade.php" >&2
exit $exit_code
EOF
    chmod +x "$BIN_DIR/impeccable"
}

seed_larv_docs() {
    mkdir -p "$TMP/docs/larv/00-discuss" "$TMP/docs/larv/03-design"
    cat >"$TMP/docs/larv/00-discuss/product-brief.md" <<'EOF'
# Product brief

Loan officers review credit files and underwrite applications.

Users: credit officers on a dense desktop CRM.

Purpose: underwrite credit applications without leaving the workspace.
EOF
    cat >"$TMP/docs/larv/03-design/brand-spec.md" <<'EOF'
# Brand spec

Primary: #9B6632
Accent: #ECCDAE
Text: #111827
Surface: #FFFFFF
Muted: #6B7280
Font: Segoe UI
EOF
    cat >"$TMP/docs/larv/03-design/design-decision.md" <<'EOF'
pick: attio-venture-html-effectiveness/22-sales-crm.html
gallery_variant: Attio Venture
EOF
}

@test "impeccable.sh help exits 0 and lists commands" {
    run bash scripts/impeccable.sh help
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "status"
    echo "$output" | grep -q "context"
    echo "$output" | grep -q "detect"
    echo "$output" | grep -q "install"
}

@test "status reports missing CLI and exits 0" {
    run env PATH="/usr/bin:/bin" LARV_IMPECCABLE_BIN="$BIN_DIR/does-not-exist" bash scripts/impeccable.sh status "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "Impeccable check"
    echo "$output" | grep -qi "missing"
}

@test "status reports ok when a stub CLI exists" {
    write_stub_impeccable 0
    run env LARV_IMPECCABLE_BIN="$BIN_DIR/impeccable" bash scripts/impeccable.sh status "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "Impeccable check"
    echo "$output" | grep -qiE "ok:|available"
}

@test "context writes PRODUCT.md DESIGN.md and detector config from larv docs" {
    seed_larv_docs
    run bash scripts/impeccable.sh context "$TMP"
    [ "$status" -eq 0 ]
    [ -f "$TMP/PRODUCT.md" ]
    [ -f "$TMP/DESIGN.md" ]
    [ -f "$TMP/.impeccable/config.json" ]
    grep -q "impeccable:product-schema" "$TMP/PRODUCT.md"
    grep -q "## Platform" "$TMP/PRODUCT.md"
    grep -q "web" "$TMP/PRODUCT.md"
    grep -q "credit officers" "$TMP/PRODUCT.md"
    grep -q "visual-implementation-contract.md" "$TMP/PRODUCT.md"
    grep -q "#9B6632" "$TMP/DESIGN.md"
    grep -q "Segoe UI" "$TMP/DESIGN.md"
    grep -q "blade.php" "$TMP/.impeccable/config.json"
    grep -q ".vue" "$TMP/.impeccable/config.json"
    grep -q "docs/larv/03-design/mockups" "$TMP/.impeccable/config.json"
    grep -q "vendor/**" "$TMP/.impeccable/config.json"
}

@test "context keeps existing PRODUCT.md unless force is set" {
    seed_larv_docs
    echo "# Product" >"$TMP/PRODUCT.md"
    echo "keep-me" >>"$TMP/PRODUCT.md"
    run bash scripts/impeccable.sh context "$TMP"
    [ "$status" -eq 0 ]
    grep -q "keep-me" "$TMP/PRODUCT.md"
    run env LARV_IMPECCABLE_FORCE=1 bash scripts/impeccable.sh context "$TMP"
    [ "$status" -eq 0 ]
    ! grep -q "keep-me" "$TMP/PRODUCT.md"
    grep -q "impeccable:product-schema" "$TMP/PRODUCT.md"
}

@test "detect skips when there is no UI surface" {
    write_stub_impeccable 2
    run env LARV_IMPECCABLE_BIN="$BIN_DIR/impeccable" bash scripts/impeccable.sh detect "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qiE "skip|no .*UI"
}

@test "detect writes a report and does not fail on findings by default" {
    write_stub_impeccable 2
    mkdir -p "$TMP/resources/views"
    echo "<div class='card'><div class='card'>nested</div></div>" >"$TMP/resources/views/app.blade.php"
    run env LARV_IMPECCABLE_BIN="$BIN_DIR/impeccable" bash scripts/impeccable.sh detect "$TMP"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/09-verification/impeccable-detect.md" ]
    [ -f "$TMP/docs/larv/09-verification/impeccable-detect.json" ]
    grep -q "nested-cards" "$TMP/docs/larv/09-verification/impeccable-detect.md"
}

@test "detect fails on findings when LARV_IMPECCABLE_STRICT=1" {
    write_stub_impeccable 2
    mkdir -p "$TMP/resources/views"
    echo "<h1>Hi</h1>" >"$TMP/resources/views/app.blade.php"
    run env LARV_IMPECCABLE_STRICT=1 LARV_IMPECCABLE_BIN="$BIN_DIR/impeccable" bash scripts/impeccable.sh detect "$TMP"
    [ "$status" -ne 0 ]
}

@test "install prints the consumer-app install command and does not run npx by default" {
    run env LARV_IMPECCABLE_BIN="$BIN_DIR/impeccable" bash scripts/impeccable.sh install "$TMP"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "npx impeccable install"
    echo "$output" | grep -q -- "--no-hooks"
}
