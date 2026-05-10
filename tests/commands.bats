#!/usr/bin/env bats

load helpers

COMMANDS=(
    larv-full larv-adopt larv-feature larv-debug
    larv-brainstorm larv-learn larv-status larv-resume
)

@test "all 8 command files exist" {
    for cmd in "${COMMANDS[@]}"; do
        [ -f "commands/${cmd}.md" ] || { echo "missing commands/${cmd}.md"; return 1; }
    done
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

@test "larv-resume command invokes resume.sh" {
    run grep -F "scripts/resume.sh" commands/larv-resume.md
    [ "$status" -eq 0 ]
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
