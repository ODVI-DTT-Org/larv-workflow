#!/usr/bin/env bats

load helpers

@test "Codex plugin manifest exists and is valid JSON" {
    [ -f .codex-plugin/plugin.json ]
    run jq empty .codex-plugin/plugin.json
    [ "$status" -eq 0 ]
}

@test "Codex plugin manifest declares larv and component paths" {
    run jq -r '.name' .codex-plugin/plugin.json
    [ "$output" = "larv" ]
    run jq -r '.skills' .codex-plugin/plugin.json
    [ "$output" = "./skills/" ]
    run jq -r '.commands' .codex-plugin/plugin.json
    [ "$output" = "./commands/" ]
}

@test "Codex plugin manifest declares interface metadata" {
    run jq -r '.interface.displayName' .codex-plugin/plugin.json
    [ "$output" = "larv" ]
    run jq -r '.interface.category' .codex-plugin/plugin.json
    [ "$output" = "Coding" ]
    run jq -r '.interface.defaultPrompt | length' .codex-plugin/plugin.json
    [ "$output" -le 3 ]
}

@test "Codex local marketplace exists and points to larv" {
    [ -f .agents/plugins/marketplace.json ]
    run jq empty .agents/plugins/marketplace.json
    [ "$status" -eq 0 ]
    run jq -r '.plugins[] | select(.name == "larv") | .source.path' .agents/plugins/marketplace.json
    [ "$output" = "./plugins/larv" ]
}

@test "Codex local marketplace entry includes required policies" {
    run jq -r '.plugins[] | select(.name == "larv") | .policy.installation' .agents/plugins/marketplace.json
    [ "$output" = "AVAILABLE" ]
    run jq -r '.plugins[] | select(.name == "larv") | .policy.authentication' .agents/plugins/marketplace.json
    [ "$output" = "ON_INSTALL" ]
    run jq -r '.plugins[] | select(.name == "larv") | .category' .agents/plugins/marketplace.json
    [ "$output" = "Coding" ]
}

@test "Codex marketplace plugin path resolves back to repo root" {
    [ -L plugins/larv ]
    local target
    target="$(cd plugins/larv && pwd -P)"
    [ "$target" = "$PROJECT_ROOT" ]
    [ -f plugins/larv/.codex-plugin/plugin.json ]
}

@test "Codex skill namespace exposes larv slash command equivalents" {
    for skill in full status resume adopt brainstorm feature debug learn; do
        [ -f "codex-skills/${skill}/SKILL.md" ] || { echo "missing codex-skills/${skill}/SKILL.md"; return 1; }
    done
    run grep -F "/larv:full" codex-skills/full/SKILL.md
    [ "$status" -eq 0 ]
}
