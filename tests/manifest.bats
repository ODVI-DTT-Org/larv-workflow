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

@test "plugin.json declares semantic version" {
    run jq -r '.version' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "plugin.json declares author as an object with a name" {
    run jq -r '.author | type' .claude-plugin/plugin.json
    [ "$output" = "object" ]
    run jq -r '.author.name' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "null" ]
}

@test "plugin.json declares a description" {
    run jq -r '.description' .claude-plugin/plugin.json
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "null" ]
}

@test "Claude marketplace manifest exposes larv plugin" {
    [ -f .claude-plugin/marketplace.json ]
    run jq empty .claude-plugin/marketplace.json
    [ "$status" -eq 0 ]
    run jq -r '.name' .claude-plugin/marketplace.json
    [ "$output" = "larv-local" ]
    run jq -r '.plugins[] | select(.name == "larv") | .source' .claude-plugin/marketplace.json
    [ "$output" = "./" ]
}
