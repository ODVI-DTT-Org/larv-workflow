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
    [ "$output" = "./codex-skills/" ]
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
    [ "$output" = "./" ]
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
    for skill in full status resume adopt brainstorm feature debug learn sandbox sandbox-start sandbox-stop sandbox-reset presentation redesign-attio-finance redesign-attio-venture feature-how-it-works feature-feedback feature-onboarding-helper larv-caveman; do
        [ -f "codex-skills/${skill}/SKILL.md" ] || { echo "missing codex-skills/${skill}/SKILL.md"; return 1; }
    done
    run grep -F "/larv:full" codex-skills/full/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv:sandbox" codex-skills/sandbox/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "sandbox.sh" codex-skills/sandbox-start/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "LARV_APP_PORT" codex-skills/sandbox-start/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv:presentation" codex-skills/presentation/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "presentation.sh" codex-skills/presentation/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv:redesign-attio-finance" codex-skills/redesign-attio-finance/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv:redesign-attio-venture" codex-skills/redesign-attio-venture/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv-feature-how-it-works" codex-skills/feature-how-it-works/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv-feature-feedback" codex-skills/feature-feedback/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv-feature-onboarding-helper" codex-skills/feature-onboarding-helper/SKILL.md
    [ "$status" -eq 0 ]
    run grep -F "/larv-caveman" codex-skills/larv-caveman/SKILL.md
    [ "$status" -eq 0 ]
}

@test "Codex larv feature entry point documents wrapper YAGNI audit" {
    grep -q "Ponytail YAGNI audit" codex-skills/feature/SKILL.md
    grep -q "docs/larv/features/<feature-slug>/yagni-audit.md" codex-skills/feature/SKILL.md
    grep -q "before handoff generation" codex-skills/feature/SKILL.md
}
