#!/usr/bin/env bats

load helpers

COMMANDS=(
    larv-full larv-adopt larv-feature larv-debug
    larv-brainstorm larv-learn larv-status larv-resume
    larv-sandbox larv-sandbox-start larv-sandbox-stop larv-sandbox-reset
    larv-caveman larv-presentation larv-redesign-attio-finance larv-redesign-attio-venture larv-feature-how-it-works
    larv-feature-feedback larv-feature-onboarding-helper larv-security
    larv-redesign-impeccable-higgsfield larv-design-setup
)

@test "all 22 command files exist" {
    for cmd in "${COMMANDS[@]}"; do
        [ -f "commands/${cmd}.md" ] || { echo "missing commands/${cmd}.md"; return 1; }
    done
}

@test "larv-security command invokes security scan" {
    grep -q "scripts/security-scan.sh" commands/larv-security.md
    grep -q "manual-security-scan.md" commands/larv-security.md
}

@test "feedback and onboarding helper commands reference bundled examples" {
    grep -q "larv-feature-feedback" commands/larv-feature-feedback.md
    grep -q "Resend" commands/larv-feature-feedback.md
    grep -q "examples/rfp/app/Domain/Feedback/Actions/SubmitFeedback.php" commands/larv-feature-feedback.md
    grep -q "examples/imu/backend-imu/src/routes/feedback.ts" commands/larv-feature-feedback.md
    grep -q "Feedback submission must persist even if email/webhook delivery fails" commands/larv-feature-feedback.md
    grep -q "larv-feature-onboarding-helper" commands/larv-feature-onboarding-helper.md
    grep -q "examples/rfp/app/Livewire/Onboarding.php" commands/larv-feature-onboarding-helper.md
    grep -q "examples/imu/frontend-web-imu/docs/architecture/user-flows.md" commands/larv-feature-onboarding-helper.md
    grep -q "capture all user flows" commands/larv-feature-onboarding-helper.md
    grep -q "show the public URL" commands/larv-feature-onboarding-helper.md
}

@test "feature how it works command references bundled guide examples" {
    grep -q "larv-feature-how-it-works" commands/larv-feature-how-it-works.md
    grep -q "/guide" commands/larv-feature-how-it-works.md
    grep -q "/how-it-works" commands/larv-feature-how-it-works.md
    grep -q "examples/rfp/resources/views/livewire/guide.blade.php" commands/larv-feature-how-it-works.md
    grep -q "examples/interview/visual-workflow/" commands/larv-feature-how-it-works.md
    grep -q "real in-app feature page" commands/larv-feature-how-it-works.md
    grep -q "each detected role/persona" commands/larv-feature-how-it-works.md
    grep -q "role-flow-inventory.md" commands/larv-feature-how-it-works.md
    grep -q "show the public URL" commands/larv-feature-how-it-works.md
}

@test "redesign commands require Attio HTML Effectiveness production redesigns" {
    grep -q "attio-finance-html-effectiveness-design/" commands/larv-redesign-attio-finance.md
    grep -q "attio-venture-html-effectiveness/" commands/larv-redesign-attio-venture.md
    grep -q "21-credit-officer-crm.html" commands/larv-redesign-attio-finance.md
    grep -q "21-credit-officer-crm.html" commands/larv-redesign-attio-venture.md
    grep -q "Preserve all backend behavior" commands/larv-redesign-attio-finance.md
    grep -q "Preserve all backend behavior" commands/larv-redesign-attio-venture.md
    grep -q "whole frontend UI" commands/larv-redesign-attio-finance.md
    grep -q "whole frontend UI" commands/larv-redesign-attio-venture.md
    grep -q "sandbox restart/probe" commands/larv-redesign-attio-finance.md
    grep -q "sandbox restart/probe" commands/larv-redesign-attio-venture.md
    grep -q "visual-parity.md" commands/larv-redesign-attio-finance.md
    grep -q "visual-parity.md" commands/larv-redesign-attio-venture.md
}

@test "impeccable-higgsfield redesign command wires setup, board and implementation" {
    f=commands/larv-redesign-impeccable-higgsfield.md
    grep -q "name: larv:redesign-impeccable-higgsfield" "$f"
    grep -q "design-setup.sh check" "$f"
    grep -q "design-directions.sh" "$f"
    grep -q "Preserve all backend behavior" "$f"
    grep -q "visual-parity.md" "$f"
    grep -q "board-url.txt" "$f"
}

@test "every command file has frontmatter" {
    for cmd in "${COMMANDS[@]}"; do
        run head -n 1 "commands/${cmd}.md"
        [ "$output" = "---" ] || { echo "no frontmatter in commands/${cmd}.md"; return 1; }
    done
}

@test "every command file declares a description" {
    for cmd in "${COMMANDS[@]}"; do
        run grep -E '^description:' "commands/${cmd}.md"
        [ "$status" -eq 0 ] || { echo "no description in commands/${cmd}.md"; return 1; }
    done
}

@test "larv-status command invokes status.sh" {
    run grep -F "scripts/status.sh" commands/larv-status.md
    [ "$status" -eq 0 ]
}

@test "larv-caveman command invokes scripts/caveman.sh" {
    run grep -F "scripts/caveman.sh" commands/larv-caveman.md
    [ "$status" -eq 0 ]
}

@test "larv-resume command invokes resume.sh" {
    run grep -F "scripts/resume.sh" commands/larv-resume.md
    [ "$status" -eq 0 ]
}

@test "sandbox commands invoke sandbox.sh lifecycle actions" {
    grep -q 'scripts/sandbox.sh "$PWD" info' commands/larv-sandbox.md
    grep -q 'scripts/sandbox.sh "$PWD" start' commands/larv-sandbox-start.md
    grep -q 'scripts/sandbox.sh "$PWD" stop' commands/larv-sandbox-stop.md
    grep -q 'scripts/sandbox.sh "$PWD" reset' commands/larv-sandbox-reset.md
    grep -q "seeded test credentials" commands/larv-sandbox.md
    grep -q "probes every public URL" commands/larv-sandbox-start.md
    grep -q "ask the user which public VM ports" commands/larv-sandbox-start.md
    grep -q "LARV_APP_PORT" commands/larv-sandbox-start.md
    grep -q "LARV_DOCS_PORT" commands/larv-sandbox-start.md
    grep -q "LARV_MOCKUPS_PORT" commands/larv-sandbox-start.md
    grep -q "migrate:fresh --seed --force" commands/larv-sandbox-reset.md
}

@test "larv-presentation command invokes presentation.sh with required port contract" {
    grep -q 'scripts/presentation.sh "$PWD" start' commands/larv-presentation.md
    grep -q "whole current repository" commands/larv-presentation.md
    grep -q "HTML Effectiveness-style" commands/larv-presentation.md
    grep -q "2000-2999" commands/larv-presentation.md
    grep -q "http://sandbox.example.com:<port>/" commands/larv-presentation.md
    grep -q "LARV_PRESENTATION_PORT" commands/larv-presentation.md
    grep -q "skills visual representation" commands/larv-presentation.md
    grep -q "dataflow loan approval" commands/larv-presentation.md
    grep -q "feature onboarding" commands/larv-presentation.md
}

@test "every command file frontmatter is valid YAML" {
    for cmd in "${COMMANDS[@]}"; do
        run python3 -c "
import yaml, sys
content = open('commands/${cmd}.md').read()
parts = content.split('---', 2)
if len(parts) < 3:
    sys.exit(2)
yaml.safe_load(parts[1])
" 2>&1
        [ "$status" -eq 0 ] || { echo "invalid YAML frontmatter in commands/${cmd}.md: $output"; return 1; }
    done
}

@test "larv-feature command describes mini-flow with gates" {
    grep -q "Laravel Superpowers brainstorming" commands/larv-feature.md
    grep -q "Laravel Superpowers writing plan" commands/larv-feature.md
    grep -q "Ponytail YAGNI audit" commands/larv-feature.md
    grep -q "docs/larv/features/<feature-slug>/yagni-audit.md" commands/larv-feature.md
    grep -q "before handoff generation" commands/larv-feature.md
    grep -q "docs/larv/features/<feature-slug>/design.md" commands/larv-feature.md
    grep -q "docs/superpowers/specs" commands/larv-feature.md
    grep -q "Per-slice handsoff" commands/larv-feature.md
    grep -q "Tracker + STATE updates" commands/larv-feature.md
    grep -q "Routing-menu hard gate" commands/larv-feature.md
    grep -q "DOCS.md" commands/larv-feature.md
    grep -q "docs/larv/08-implementation/reports/" commands/larv-feature.md
    grep -q "visual-implementation-contract.md" commands/larv-feature.md
    grep -q "desktop/mobile screenshot checks" commands/larv-feature.md
    grep -q "exact chosen mockup files" commands/larv-feature.md
    grep -q "production screen should look like the selected mockup" commands/larv-feature.md
    grep -q "seeded test credentials" commands/larv-feature.md
    grep -q "normal login" commands/larv-feature.md
    ! grep -q "User Switcher" commands/larv-feature.md
    ! grep -q "DEMO_MODE" commands/larv-feature.md
    grep -q "restart/probe the sandbox" commands/larv-feature.md
    grep -q "Do not ask the user to run migrations" commands/larv-feature.md
}

@test "larv-debug command describes mini-flow with regression test" {
    grep -q "Domain-context check" commands/larv-debug.md
    grep -q "regression test" commands/larv-debug.md
    grep -q "Tracker entry" commands/larv-debug.md
    grep -q "Implementation hard gate" commands/larv-debug.md
    grep -q "restart/probe the sandbox" commands/larv-debug.md
    grep -q "Do not ask the user to run migrations" commands/larv-debug.md
}

@test "larv-full command requires AI-owned sandbox runtime work" {
    grep -q "AI owns sandbox execution" commands/larv-full.md
    grep -q "restart/probe the sandbox" commands/larv-full.md
    grep -q "Do not ask the user to run migrations" commands/larv-full.md
}
