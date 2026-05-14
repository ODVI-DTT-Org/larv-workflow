#!/usr/bin/env bats

load helpers

@test "README.md exists at repo root" {
    [ -f README.md ]
}

@test "README.md mentions all 12 commands" {
    for cmd in /larv:full /larv:adopt /larv:feature /larv:debug /larv:brainstorm /larv:learn /larv:status /larv:resume /larv:sandbox /larv:sandbox-start /larv:sandbox-stop /larv:sandbox-reset; do
        run grep -F "$cmd" README.md
        [ "$status" -eq 0 ]
    done
}

@test "README.md contains greenfield todo example" {
    run grep -F "Example 1" README.md
    [ "$status" -eq 0 ]
}

@test "README documents happy path and hooks" {
    grep -q "Happy path" README.md
    grep -q "hooks" README.md
    grep -q "Codex CLI" README.md
    grep -q "package-guide.md" README.md
    grep -q "http://31.220.79.31:<port>" README.md
    grep -q 'never `127.0.0.1` or `localhost`' README.md
}
