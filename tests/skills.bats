#!/usr/bin/env bats

load helpers

SKILLS=(
    larv-orchestrator larv-domain-interview larv-discuss larv-domain larv-architecture
    larv-design larv-tests larv-premortem larv-plan larv-provision
    larv-implement larv-verify larv-deploy larv-learn larv-handoff
    larv-adopt larv-docsite
)

@test "all 17 skill files exist" {
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

@test "remaining skill stubs flag themselves as stubs" {
    for skill in larv-premortem; do
        run grep -F "STUB" "skills/${skill}/SKILL.md"
        [ "$status" -eq 0 ] || { echo "${skill} not marked STUB"; return 1; }
    done
}

@test "larv-architecture is filled and propagates package decisions" {
    ! grep -q "STUB" skills/larv-architecture/SKILL.md
    grep -q "library-decisions.md" skills/larv-architecture/SKILL.md
    grep -q "package-integration-matrix.md" skills/larv-architecture/SKILL.md
    grep -q "Filament" skills/larv-architecture/SKILL.md
    grep -q "Horizon" skills/larv-architecture/SKILL.md
    grep -q "Cashier" skills/larv-architecture/SKILL.md
    grep -q "tenancy" skills/larv-architecture/SKILL.md
}

@test "larv-tests is filled and requires package-specific tests" {
    ! grep -q "STUB" skills/larv-tests/SKILL.md
    grep -q "package-test-matrix.md" skills/larv-tests/SKILL.md
    grep -q "Filament" skills/larv-tests/SKILL.md
    grep -q "Cashier" skills/larv-tests/SKILL.md
    grep -q "Horizon" skills/larv-tests/SKILL.md
    grep -q "Scout" skills/larv-tests/SKILL.md
}

@test "larv-plan requires package slices from approved packages" {
    grep -q "package-integration-matrix.md" skills/larv-plan/SKILL.md
    grep -q "package-test-matrix.md" skills/larv-plan/SKILL.md
    grep -q "Filament" skills/larv-plan/SKILL.md
    grep -q "Cashier" skills/larv-plan/SKILL.md
    grep -q "Horizon" skills/larv-plan/SKILL.md
    grep -q "Scout" skills/larv-plan/SKILL.md
    grep -q "package-slice-snippets" skills/larv-plan/SKILL.md
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
    grep -q "Do not dispatch this during" skills/larv-provision/SKILL.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" skills/larv-provision/SKILL.md
    grep -q "Bootstrap Invariants" skills/larv-provision/SKILL.md
}

@test "larv-implement SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-implement/SKILL.md
    grep -q "Handsoff/slice-NN" skills/larv-implement/SKILL.md
    grep -q "self-contained" skills/larv-implement/SKILL.md
}

@test "larv-plan SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-plan/SKILL.md
    grep -q "Elephant Carpaccio" skills/larv-plan/SKILL.md
    grep -q "deploy-sandbox.sh" skills/larv-plan/SKILL.md
}

@test "larv-implement does not reference plugin lib scripts" {
    # spec discipline §3.2: implement reads handsoff, which is self-contained
    if grep -E 'scripts/lib/[a-z_]+\.sh' skills/larv-implement/SKILL.md; then
        echo "FAIL: larv-implement references plugin lib scripts" >&2
        return 1
    fi
}

@test "larv-orchestrator SKILL.md describes required gates" {
    grep -q "soft_gate" skills/larv-orchestrator/SKILL.md
    ! grep -q "hard_gate" skills/larv-orchestrator/SKILL.md
    grep -q "routing_menu" skills/larv-orchestrator/SKILL.md
    grep -q "Phase 8 routing menu" skills/larv-orchestrator/SKILL.md
}

@test "larv-orchestrator handles all three execution modes" {
    grep -q "executing-same-session" skills/larv-orchestrator/SKILL.md
    grep -q "executing-subagents" skills/larv-orchestrator/SKILL.md
    grep -q "handed-off-external" skills/larv-orchestrator/SKILL.md
}

@test "larv-domain-interview SKILL.md exists with valid frontmatter" {
    [ -f skills/larv-domain-interview/SKILL.md ]
    grep -q "^name: larv-domain-interview" skills/larv-domain-interview/SKILL.md
    grep -q "Phase 0a" skills/larv-domain-interview/SKILL.md
    grep -qi "tech-leak guard" skills/larv-domain-interview/SKILL.md
}

@test "larv-discuss SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-discuss/SKILL.md
    grep -q "Filament" skills/larv-discuss/SKILL.md
    grep -q "Horizon" skills/larv-discuss/SKILL.md
    grep -q "Pulse" skills/larv-discuss/SKILL.md
    grep -q "Cashier" skills/larv-discuss/SKILL.md
}

@test "larv-domain SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-domain/SKILL.md
    grep -q "medium.com/@harryespant" skills/larv-domain/SKILL.md
    grep -qi "viability" skills/larv-domain/SKILL.md
}

@test "larv-design SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-design/SKILL.md
    grep -q "getdesign.md" skills/larv-design/SKILL.md
    grep -q "allocate_port mockup" skills/larv-design/SKILL.md
    grep -qi "probe-before-announce" skills/larv-design/SKILL.md
}

@test "larv-design makes mockup URL a mandatory completion gate" {
    grep -q "Mandatory completion gate" skills/larv-design/SKILL.md
    grep -q "mockup_url" skills/larv-design/SKILL.md
    grep -q "status: failed" skills/larv-design/SKILL.md
    grep -q "Do not proceed to brand finalization" skills/larv-design/SKILL.md
    grep -q "mockup_url: \"http://31.220.79.31:<port>/\"" skills/larv-design/SKILL.md
    grep -q "static_server_check_remote_deps" skills/larv-design/SKILL.md
    grep -q "runtime_gate_require_phase_url . design" skills/larv-design/SKILL.md
    grep -q "mockups_dir" skills/larv-design/SKILL.md
    ! grep -q "/srv/larv/.*/mockups" skills/larv-design/SKILL.md
    grep -q "static_server_open_firewall" skills/larv-design/SKILL.md
    grep -q "refusing to announce local-only mockup URL" skills/larv-design/SKILL.md
    grep -q "http://31.220.79.31:<port>/" skills/larv-design/SKILL.md
}

@test "larv-docsite SKILL.md exists for Phase 6.5" {
    [ -f skills/larv-docsite/SKILL.md ]
    grep -q "^name: larv-docsite" skills/larv-docsite/SKILL.md
    grep -q "Phase 6.5" skills/larv-docsite/SKILL.md
    grep -q "allocate_port docsite" skills/larv-docsite/SKILL.md
    grep -q "Docsify" skills/larv-docsite/SKILL.md
}

@test "larv-docsite makes docsite URL a mandatory completion gate" {
    grep -q "Mandatory completion gate" skills/larv-docsite/SKILL.md
    grep -q "docsite_url" skills/larv-docsite/SKILL.md
    grep -q "status: failed" skills/larv-docsite/SKILL.md
    grep -q "docsite_url: \"http://31.220.79.31:<port>/\"" skills/larv-docsite/SKILL.md
    grep -q "static_server_check_remote_deps" skills/larv-docsite/SKILL.md
    grep -q "runtime_gate_require_phase_url . docsite" skills/larv-docsite/SKILL.md
    grep -q "docs/Handsoff.md" skills/larv-docsite/SKILL.md
    grep -q "docs/Handsoff/" skills/larv-docsite/SKILL.md
    grep -q "docsite_root=\"/tmp/larv-" skills/larv-docsite/SKILL.md
    ! grep -q "/srv/larv/.*/docsite" skills/larv-docsite/SKILL.md
    grep -q "static_server_open_firewall" skills/larv-docsite/SKILL.md
    grep -q "refusing to announce local-only doc-site URL" skills/larv-docsite/SKILL.md
    grep -q "http://31.220.79.31:<port>/" skills/larv-docsite/SKILL.md
}

@test "larv-provision redirects active sandbox startup to handoff bootstrap" {
    grep -q "Do not dispatch this during" skills/larv-provision/SKILL.md
    grep -q "app sandbox belongs to implementation handoff" skills/larv-provision/SKILL.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" skills/larv-provision/SKILL.md
    grep -q "Print the sandbox URL only after both probes pass" skills/larv-provision/SKILL.md
    grep -q "not from larv-provision during /larv:full" skills/larv-provision/SKILL.md
}

@test "larv-plan requires deploy-sandbox script for handoff bootstrap" {
    grep -q "deploy-sandbox.sh" skills/larv-plan/SKILL.md
    grep -q "executable" skills/larv-plan/SKILL.md
    grep -q "APP_PORT" skills/larv-plan/SKILL.md
    grep -q "DB_DATABASE" skills/larv-plan/SKILL.md
    grep -q "Handoff bootstrap refuses" skills/larv-plan/SKILL.md
}

@test "larv-orchestrator describes Phase 0a and Phase 6.5 in greenfield sequence" {
    grep -q "Phase 0a" skills/larv-orchestrator/SKILL.md
    grep -q "Phase 6.5" skills/larv-orchestrator/SKILL.md
    grep -q "larv-domain-interview" skills/larv-orchestrator/SKILL.md
    grep -q "larv-docsite" skills/larv-orchestrator/SKILL.md
}

@test "larv-orchestrator rejects missing runtime URLs for server phases" {
    grep -q "Runtime URL enforcement" skills/larv-orchestrator/SKILL.md
    grep -q "mockup_url" skills/larv-orchestrator/SKILL.md
    grep -q "docsite_url" skills/larv-orchestrator/SKILL.md
    ! grep -q "sandbox_url" skills/larv-orchestrator/SKILL.md
    grep -q "treat the phase as failed" skills/larv-orchestrator/SKILL.md
    grep -q "127.0.0.1" skills/larv-orchestrator/SKILL.md
    grep -q "firewall handling" skills/larv-orchestrator/SKILL.md
}

@test "larv-orchestrator shows handoff paths before execution routing" {
    grep -q "docs/Handsoff.md" skills/larv-orchestrator/SKILL.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" skills/larv-orchestrator/SKILL.md
    grep -q "docs/Handsoff/slice-NN-<name>.md" skills/larv-orchestrator/SKILL.md
    grep -q "docs/larv/docsite-url.txt" skills/larv-orchestrator/SKILL.md
}

@test "larv-implement requires sandbox bootstrap before slices" {
    grep -q "Bootstrap — mandatory before first slice" skills/larv-implement/SKILL.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" skills/larv-implement/SKILL.md
    grep -q "docs/larv/07-runtime/sandbox-url.txt" skills/larv-implement/SKILL.md
}

@test "larv-handoff renders production and user guide documents" {
    grep -q "handsoff_render_runtime_guides" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/production-deploy.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/env-guide.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/operations-guide.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/package-guide.md" skills/larv-handoff/SKILL.md
}

@test "larv-deploy is filled with Laravel Cloud and Namecheap handoff guidance" {
    ! grep -q "STUB" skills/larv-deploy/SKILL.md
    grep -q "Laravel Cloud" skills/larv-deploy/SKILL.md
    grep -q "Namecheap" skills/larv-deploy/SKILL.md
    grep -q "docs/Handsoff/production-deploy.md" skills/larv-deploy/SKILL.md
    grep -q "Ask the user" skills/larv-deploy/SKILL.md
}

@test "larv-verify is filled with concrete verification checks" {
    ! grep -q "STUB" skills/larv-verify/SKILL.md
    grep -q "vendor/bin/pest" skills/larv-verify/SKILL.md
    grep -q "vendor/bin/pint --test" skills/larv-verify/SKILL.md
    grep -q "vendor/bin/phpstan analyse" skills/larv-verify/SKILL.md
    grep -q "docs/larv/09-verification/final-report.md" skills/larv-verify/SKILL.md
}

@test "phase prompts reference required bundled skills" {
    grep -q "bundle/domain-driven-design" skills/larv-domain/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-c4-architecture" skills/larv-architecture/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-test-strategy" skills/larv-tests/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-bug-premortem" skills/larv-premortem/SKILL.md
    grep -q "bundle/superpowers-laravel/skills" skills/larv-implement/SKILL.md
    grep -q "bundle/huashu-design/SKILL.md" skills/larv-design/SKILL.md
}

@test "larv-adopt detects existing Laravel package surface" {
    grep -q "composer.json" skills/larv-adopt/SKILL.md
    grep -q "package-detection.md" skills/larv-adopt/SKILL.md
    grep -q "Filament" skills/larv-adopt/SKILL.md
    grep -q "Horizon" skills/larv-adopt/SKILL.md
    grep -q "Cashier" skills/larv-adopt/SKILL.md
    grep -q "Telescope" skills/larv-adopt/SKILL.md
}

@test "larv-learn aggregates implementation reports and supports dry run" {
    ! grep -q "STUB" skills/larv-learn/SKILL.md
    grep -q "IMPLEMENTATION-REPORT" skills/larv-learn/SKILL.md
    grep -q "local-learnings.md" skills/larv-learn/SKILL.md
    grep -q -- "--dry-run" skills/larv-learn/SKILL.md
    grep -q "LEARNINGS.md" skills/larv-learn/SKILL.md
}

@test "larv-deploy includes Laravel Cloud automation mode" {
    grep -q "guide-only" skills/larv-deploy/SKILL.md
    grep -q "automation mode" skills/larv-deploy/SKILL.md
    grep -q "Laravel Cloud CLI" skills/larv-deploy/SKILL.md
    grep -q "Laravel Cloud API" skills/larv-deploy/SKILL.md
    grep -q "LARAVEL_CLOUD_API_TOKEN" skills/larv-deploy/SKILL.md
    grep -q "Namecheap API" skills/larv-deploy/SKILL.md
    grep -q "NAMECHEAP_CLIENT_IP" skills/larv-deploy/SKILL.md
    grep -q "automation choice" skills/larv-deploy/SKILL.md
}
