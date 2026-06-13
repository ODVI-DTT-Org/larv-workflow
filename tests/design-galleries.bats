#!/usr/bin/env bats

load helpers

@test "design systems README defines unified Attio template contract" {
    grep -q "Unified Attio Template Contract" DESIGN-SYSTEMS-README.md
    grep -q "single source of truth" DESIGN-SYSTEMS-README.md
    grep -q "templates/attio-crm-workspace.html" DESIGN-SYSTEMS-README.md
    grep -q "Do not send Phase 3 users to external design galleries" DESIGN-SYSTEMS-README.md
    grep -q "Attio Finance" DESIGN-SYSTEMS-README.md
    grep -q "Attio Venture" DESIGN-SYSTEMS-README.md
    grep -q "attio-venture-html-effectiveness/" DESIGN-SYSTEMS-README.md
    grep -q "Custom" DESIGN-SYSTEMS-README.md
}

@test "Attio Venture HTML Effectiveness alias points to Attio Venture gallery" {
    [ -e attio-venture-html-effectiveness ]
    [ -f attio-venture-html-effectiveness/index.html ]
    [ -f attio-venture-html-effectiveness/attio-venture-logo.png ]
    grep -q "Canonical Phase 3 alias" DESIGN-SYSTEMS-README.md
}

@test "Attio Finance and Attio Venture stylesheets expose Attio foundation tokens" {
    for css in attio-finance-html-effectiveness-design/design-system.css attio-venture-html-effectiveness-design/design-system.css; do
        grep -q "Unified Attio foundation" "$css"
        grep -q -- "--attio-surface" "$css"
        grep -q -- "--attio-surface-muted" "$css"
        grep -q -- "--attio-border" "$css"
        grep -q -- "--attio-focus-ring" "$css"
        grep -q -- "--attio-card-radius" "$css"
        grep -q -- "--attio-control-radius" "$css"
    done
}

@test "Attio Finance and Attio Venture gallery pages include browser URL logo links" {
    for html in attio-finance-html-effectiveness-design/*.html; do
        grep -q 'rel="icon" type="image/png" href="attio-finance-logo.png"' "$html"
        grep -q 'rel="apple-touch-icon" href="attio-finance-logo.png"' "$html"
    done

    for html in attio-venture-html-effectiveness-design/*.html; do
        grep -q 'rel="icon" type="image/png" href="attio-venture-logo.png"' "$html"
        grep -q 'rel="apple-touch-icon" href="attio-venture-logo.png"' "$html"
    done
}

@test "Attio Finance and Attio Venture primary templates keep visible app logos" {
    for html in \
        attio-finance-html-effectiveness-design/index.html \
        attio-finance-html-effectiveness-design/21-credit-officer-crm.html \
        attio-finance-html-effectiveness-design/22-sales-crm.html \
        attio-finance-html-effectiveness-design/23-service-crm.html; do
        grep -q '<img src="attio-finance-logo.png"' "$html"
    done

    for html in \
        attio-venture-html-effectiveness-design/index.html \
        attio-venture-html-effectiveness-design/21-credit-officer-crm.html \
        attio-venture-html-effectiveness-design/22-sales-crm.html \
        attio-venture-html-effectiveness-design/23-service-crm.html; do
        grep -q '<img src="attio-venture-logo.png"' "$html"
    done
}
