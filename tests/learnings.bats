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

@test "LEARNINGS.md contains curated plugin learning entries" {
    run grep -cE "^(- \\[plugin\\]|\\[plugin\\])" LEARNINGS.md
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}
