#!/usr/bin/env bats

load helpers

SKILLS=(
    larv-orchestrator larv-discuss larv-domain larv-architecture
    larv-design larv-tests larv-premortem larv-plan larv-provision
    larv-implement larv-verify larv-deploy larv-learn larv-handoff
    larv-adopt
)

@test "all 15 skill files exist" {
    for skill in "${SKILLS[@]}"; do
        [ -f "skills/${skill}/SKILL.md" ] || { echo "missing skills/${skill}/SKILL.md"; return 1; }
    done
}

@test "every skill has frontmatter with name and description" {
    for skill in "${SKILLS[@]}"; do
        run grep -E '^name:' "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "no name in ${skill}"; return 1; }
        run grep -E '^description:' "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "no description in ${skill}"; return 1; }
    done
}

@test "every skill stub flags itself as a stub deferring to sub-project B" {
    for skill in larv-discuss larv-domain larv-architecture larv-design \
                 larv-tests larv-premortem larv-plan \
                 larv-implement larv-verify larv-deploy larv-learn \
                 larv-adopt; do
        run grep -F "STUB" "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "${skill} not marked STUB"; return 1; }
    done
}

@test "every skill SKILL.md frontmatter is valid YAML" {
    for skill in "${SKILLS[@]}"; do
        run python3 -c "
import yaml, sys
content = open('skills/${skill}/SKILL.md').read()
parts = content.split('---', 2)
if len(parts) < 3:
    sys.exit(2)
yaml.safe_load(parts[1])
" 2>&1
        [ "$status" -eq 0 ] || { echo "invalid YAML frontmatter in skills/${skill}/SKILL.md: $output"; return 1; }
    done
}

@test "larv-handoff SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-handoff/SKILL.md
    grep -q "handsoff_render_index" skills/larv-handoff/SKILL.md
    grep -q "handsoff_render_starting_points" skills/larv-handoff/SKILL.md
}

@test "larv-provision SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-provision/SKILL.md
    grep -q "allocate_port" skills/larv-provision/SKILL.md
    grep -q "probe_with_retries" skills/larv-provision/SKILL.md
}
