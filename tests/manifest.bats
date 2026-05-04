#!/usr/bin/env bats

load helpers

@test "plugin.json is valid JSON" {
    run jq empty .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
}

@test "plugin.json declares name larv" {
    run jq -r '.name' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ "$output" = "larv" ]
}

@test "plugin.json lists exactly 8 commands" {
    run jq '.commands | length' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ "$output" = "8" ]
}

@test "plugin.json lists exactly 15 skills" {
    run jq '.skills | length' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ "$output" = "15" ]
}

@test "plugin.json declares semantic version" {
    run jq -r '.version' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
