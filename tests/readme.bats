#!/usr/bin/env bats

load helpers

@test "README.md exists at repo root" {
    [ -f README.md ]
}

@test "README.md mentions all 8 commands" {
    for cmd in /larv:full /larv:adopt /larv:feature /larv:debug /larv:brainstorm /larv:learn /larv:status /larv:resume; do
        run grep -F "$cmd" README.md
        [ "$status" -eq 0 ]
    done
}

@test "README.md contains greenfield todo example" {
    run grep -F "Example 1" README.md
    [ "$status" -eq 0 ]
}
