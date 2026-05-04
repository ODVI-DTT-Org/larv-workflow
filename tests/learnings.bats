#!/usr/bin/env bats

load helpers

@test "LEARNINGS.md exists at repo root" {
    [ -f LEARNINGS.md ]
}

@test "LEARNINGS.md has all documented section headings" {
    for section in \
        "Library version notes" \
        "Discuss-phase questions" \
        "Patterns promoted" \
        "Failure modes prevented" \
        "Composition lessons"; do
        run grep -F "## $section" LEARNINGS.md
        [ "$status" -eq 0 ] || { echo "missing section: $section"; return 1; }
    done
}

@test "LEARNINGS.md initial state has no real entries just structure" {
    run grep -cE "^- " LEARNINGS.md
    [ "$output" -le 5 ]
}
