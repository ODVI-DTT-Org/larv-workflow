#!/usr/bin/env bats

load helpers

@test "README.md exists at repo root" {
    [ -f README.md ]
}

@test "README.md mentions all public commands" {
    for cmd in /larv:full /larv:adopt /larv:feature /larv:debug /larv:brainstorm /larv:learn /larv-caveman /larv:status /larv:resume /larv:sandbox /larv:sandbox-start /larv:sandbox-stop /larv:sandbox-reset /larv:presentation /larv:security /larv:redesign-attio-finance /larv:redesign-attio-venture /larv-feature-how-it-works /larv-feature-feedback /larv-feature-onboarding-helper /larv:redesign-impeccable-higgsfield /larv:design-setup; do
        run grep -F "$cmd" README.md
        [ "$status" -eq 0 ]
    done
}

@test "README documents install and setup" {
    grep -q "Claude Code" README.md
    grep -q "Codex CLI" README.md
    grep -q "claude plugin install" README.md
    grep -q "codex plugin marketplace add" README.md
    grep -q "LARV_VM_HOST" README.md
    grep -q "sandbox.example.com" README.md
}

@test "README documents feature helper commands" {
    grep -q "/larv-feature-feedback" README.md
    grep -q "authenticated in-app feedback" README.md
    grep -q "/larv-feature-onboarding-helper" README.md
    grep -q "user-flow inventory" README.md
    grep -q "/larv-feature-how-it-works" README.md
    grep -q "/guide" README.md
    grep -q "/how-it-works" README.md
}

@test "README documents redesign commands" {
    grep -q "redesign-attio-finance" README.md
    grep -q "redesign-attio-venture" README.md
    grep -q "attio-finance-html-effectiveness-design/" README.md
    grep -q "attio-venture-html-effectiveness/" README.md
    grep -q "production app is redesigned" README.md
}

@test "README documents greenfield workflow and phases" {
    grep -q "Quick Start" README.md
    grep -q "/larv:full Build" README.md
    grep -q "Greenfield Phases" README.md
    grep -q "larv-domain-interview" README.md
    grep -q "larv-handoff" README.md
    grep -q "larv-verify" README.md
}

@test "README documents generated artifacts" {
    grep -q "Generated Artifacts" README.md
    grep -q "docs/larv/STATE.yaml" README.md
    grep -q "docs/Handsoff.md" README.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" README.md
    grep -q "docs/Handsoff/slice-NN-" README.md
    grep -q "package-guide.md" README.md
}

@test "README documents design galleries" {
    grep -q "Attio" README.md
    grep -q "attio-finance-html-effectiveness-design/" README.md
    grep -q "attio-venture-html-effectiveness/" README.md
    grep -q "Attio Finance" README.md
    grep -q "Attio Venture" README.md
}

@test "README documents security and publishing checklist" {
    grep -q "Security" README.md
    grep -q "scripts/security-scan.sh" README.md
    grep -q "non-executing" README.md
    grep -q "Publishing Checklist" README.md
    grep -q "MIT" README.md
    grep -q "LICENSE" README.md
}

@test "README documents Impeccable + Higgsfield design directions" {
    grep -q "## Impeccable + Higgsfield design directions" README.md
    grep -q "/larv:redesign-impeccable-higgsfield" README.md
    grep -q "nano_banana_pro" README.md
    grep -q "LARV_HIGGSFIELD_CREDIT_CAP" README.md
    grep -q "FICTIONAL-DATA-CONFIRMED" README.md
}
