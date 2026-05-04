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
