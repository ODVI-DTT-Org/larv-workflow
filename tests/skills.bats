#!/usr/bin/env bats

load helpers

SKILLS=(
    larv-orchestrator larv-domain-interview larv-discuss larv-domain larv-architecture
    larv-design larv-tests larv-premortem larv-plan larv-provision
    larv-implement larv-verify larv-deploy larv-learn larv-handoff
    larv-adopt larv-docsite larv-presentation larv-redesign-attio-finance larv-redesign-attio-venture
    larv-feature-how-it-works larv-feature-feedback larv-feature-onboarding-helper
    larv-security larv-headroom
    larv-redesign-impeccable-higgsfield
)

@test "all 25 skill files exist" {
    for skill in "${SKILLS[@]}"; do
        [ -f "skills/${skill}/SKILL.md" ] || { echo "missing skills/${skill}/SKILL.md"; return 1; }
    done
}

@test "larv-security skill defines repository guard coverage" {
    grep -q "scripts/security-scan.sh" skills/larv-security/SKILL.md
    grep -q "Composer install/update" skills/larv-security/SKILL.md
    grep -q "npm install/build" skills/larv-security/SKILL.md
    grep -q "Git hooks" skills/larv-security/SKILL.md
    grep -q "lifecycle scripts" skills/larv-security/SKILL.md
    grep -q "LARV_SECURITY_ALLOW_FAIL=1" skills/larv-security/SKILL.md
}

@test "feedback and onboarding helper skills enforce required implementation contracts" {
    grep -q "/larv-feature-feedback" skills/larv-feature-feedback/SKILL.md
    grep -q "Resend Requirements" skills/larv-feature-feedback/SKILL.md
    grep -q "MAIL_MAILER=resend" skills/larv-feature-feedback/SKILL.md
    grep -q "RESEND_API_KEY" skills/larv-feature-feedback/SKILL.md
    grep -q "Feedback persistence must not depend on email success" skills/larv-feature-feedback/SKILL.md
    grep -q "examples/rfp/app/Livewire/Feedback/FeedbackWidget.php" skills/larv-feature-feedback/SKILL.md
    grep -q "examples/imu/frontend-web-imu/src/components/feedback/FeedbackWidget.vue" skills/larv-feature-feedback/SKILL.md
    grep -q "/larv-feature-onboarding-helper" skills/larv-feature-onboarding-helper/SKILL.md
    grep -q "Required User-Flow Capture" skills/larv-feature-onboarding-helper/SKILL.md
    grep -q "user-flow-inventory.md" skills/larv-feature-onboarding-helper/SKILL.md
    grep -q "examples/rfp/app/Http/Middleware/RedirectToOnboarding.php" skills/larv-feature-onboarding-helper/SKILL.md
    grep -q "examples/imu/frontend-mobile-imu/imu_flutter/docs/USER_FLOW_DOCUMENTATION.md" skills/larv-feature-onboarding-helper/SKILL.md
}

@test "feature how it works skill enforces in-app guide implementation" {
    grep -q "/larv-feature-how-it-works" skills/larv-feature-how-it-works/SKILL.md
    grep -q "examples/rfp/resources/views/livewire/guide.blade.php" skills/larv-feature-how-it-works/SKILL.md
    grep -q "examples/interview/visual-workflow/" skills/larv-feature-how-it-works/SKILL.md
    grep -q "production How It Works or Guide feature page" skills/larv-feature-how-it-works/SKILL.md
    grep -q "docs/larv/features/how-it-works/design.md" skills/larv-feature-how-it-works/SKILL.md
    grep -q "role-flow-inventory.md" skills/larv-feature-how-it-works/SKILL.md
    grep -q "every detected role/persona" skills/larv-feature-how-it-works/SKILL.md
    grep -q "docs/user-manual/how-it-works.md" skills/larv-feature-how-it-works/SKILL.md
    grep -q "Do not create only markdown documentation" skills/larv-feature-how-it-works/SKILL.md
    grep -q "public VM URL" skills/larv-feature-how-it-works/SKILL.md
}

@test "redesign skills enforce Attio Finance and Attio Venture CRM production redesigns" {
    grep -q "/larv:redesign-attio-finance" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "/larv:redesign-attio-venture" skills/larv-redesign-attio-venture/SKILL.md
    grep -q "attio-finance-html-effectiveness-design/" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "attio-venture-html-effectiveness/" skills/larv-redesign-attio-venture/SKILL.md
    grep -q "production app redesign" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "production app redesign" skills/larv-redesign-attio-venture/SKILL.md
    grep -q "screen-inventory.md" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "screen-inventory.md" skills/larv-redesign-attio-venture/SKILL.md
    grep -q "visual-parity.md" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "visual-parity.md" skills/larv-redesign-attio-venture/SKILL.md
    grep -q "Do not ask the user to run" skills/larv-redesign-attio-finance/SKILL.md
    grep -q "Do not ask the user to run" skills/larv-redesign-attio-venture/SKILL.md
}

@test "larv-presentation serves visual workflows on ports 2000-2999" {
    grep -q "/larv:presentation" skills/larv-presentation/SKILL.md
    grep -q "whole repo" skills/larv-presentation/SKILL.md
    grep -q "role/persona" skills/larv-presentation/SKILL.md
    grep -q "HTML Effectiveness" skills/larv-presentation/SKILL.md
    grep -q "docs/larv/presentation/index.html" skills/larv-presentation/SKILL.md
    grep -q "2000-2999" skills/larv-presentation/SKILL.md
    grep -q "http://sandbox.example.com:<port>/" skills/larv-presentation/SKILL.md
    grep -q "Do not SSH" skills/larv-presentation/SKILL.md
    grep -q "skills visual representation" skills/larv-presentation/SKILL.md
    grep -q "dataflow <feature>" skills/larv-presentation/SKILL.md
    grep -q "feature <name>" skills/larv-presentation/SKILL.md
    grep -q "Do not ask for clarification" skills/larv-presentation/SKILL.md
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
    grep -q "concise AI starting-point routing files" skills/larv-handoff/SKILL.md
    ! grep -q "docs/larv/AGENTS.md" skills/larv-handoff/SKILL.md
    ! grep -q "app/AGENTS.md" skills/larv-handoff/SKILL.md
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
    grep -q "section 12.1" skills/larv-implement/SKILL.md
    grep -q "section 12.2" skills/larv-implement/SKILL.md
    grep -q "Never ask the user to run sandbox verification commands manually" skills/larv-implement/SKILL.md
    grep -q "queue/runtime restarts" skills/larv-implement/SKILL.md
    grep -q "every page, route, state, credential role, and planned flow" skills/larv-implement/SKILL.md
}

@test "larv-plan SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-plan/SKILL.md
    grep -q "Elephant Carpaccio" skills/larv-plan/SKILL.md
    grep -q "deploy-sandbox.sh" skills/larv-plan/SKILL.md
    grep -q "visual-implementation-contract.md" skills/larv-plan/SKILL.md
    grep -q "screenshot parity acceptance criteria" skills/larv-plan/SKILL.md
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
    grep -q "generated AI entry points" skills/larv-orchestrator/SKILL.md
}

@test "larv-orchestrator handles all three execution modes" {
    grep -q "executing-same-session" skills/larv-orchestrator/SKILL.md
    grep -q "executing-subagents" skills/larv-orchestrator/SKILL.md
    grep -q "handed-off-external" skills/larv-orchestrator/SKILL.md
    grep -q "Laravel Superpowers brainstorming" skills/larv-orchestrator/SKILL.md
    grep -q "docs/larv/features/<feature-slug>/design.md" skills/larv-orchestrator/SKILL.md
    grep -q "docs/superpowers/plans" skills/larv-orchestrator/SKILL.md
}

@test "larv feature wrapper requires Ponytail YAGNI audit before handoff" {
    grep -q "Ponytail YAGNI audit" skills/larv-orchestrator/SKILL.md
    grep -q "docs/larv/features/<feature-slug>/yagni-audit.md" skills/larv-orchestrator/SKILL.md
    grep -q "remove unrequested feature scope" skills/larv-orchestrator/SKILL.md
    grep -q "one small slice instead of several" skills/larv-orchestrator/SKILL.md
    grep -q "before handoff generation" skills/larv-orchestrator/SKILL.md
    grep -q "need/not-needed decision" skills/larv-orchestrator/SKILL.md
    grep -q "reused existing screens/config/workflows" skills/larv-orchestrator/SKILL.md
    grep -q "rejected packages or abstractions" skills/larv-orchestrator/SKILL.md
    grep -q "slice-count rationale" skills/larv-orchestrator/SKILL.md
    grep -q "protected items not simplified away" skills/larv-orchestrator/SKILL.md
    grep -q "not remove security, validation, accessibility, or explicitly requested scope" skills/larv-orchestrator/SKILL.md
}

@test "larv-domain-interview SKILL.md exists with valid frontmatter" {
    [ -f skills/larv-domain-interview/SKILL.md ]
    grep -q "^name: larv-domain-interview" skills/larv-domain-interview/SKILL.md
    grep -q "Phase 0a" skills/larv-domain-interview/SKILL.md
    grep -qi "tech-leak guard" skills/larv-domain-interview/SKILL.md
}

@test "larv-domain-interview does not skip questions when PRD is provided" {
    grep -q "PRD-assisted interview mode" skills/larv-domain-interview/SKILL.md
    grep -q "A PRD reduces question count; it never replaces the interview" skills/larv-domain-interview/SKILL.md
    grep -q "inferred answers" skills/larv-domain-interview/SKILL.md
    grep -q "at least 5 targeted confirmation or gap questions" skills/larv-domain-interview/SKILL.md
    grep -q "Do not return status: complete" skills/larv-domain-interview/SKILL.md
}

@test "larv-discuss SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-discuss/SKILL.md
    grep -q "first user-facing question" skills/larv-discuss/SKILL.md
    grep -q "Required starting question: design direction" skills/larv-discuss/SKILL.md
    grep -q "Before we choose Laravel packages" skills/larv-discuss/SKILL.md
    grep -q "docs/larv/00-discuss/design-preferences.md" skills/larv-discuss/SKILL.md
    grep -q "templates/attio-crm-workspace.html" skills/larv-discuss/SKILL.md
    grep -q "Filament" skills/larv-discuss/SKILL.md
    grep -q "Horizon" skills/larv-discuss/SKILL.md
    grep -q "Pulse" skills/larv-discuss/SKILL.md
    grep -q "Cashier" skills/larv-discuss/SKILL.md
}

@test "larv-design consumes Phase 0 design preference" {
    grep -q "docs/larv/00-discuss/design-preferences.md" skills/larv-design/SKILL.md
    grep -q "mode: agent-recommendations" skills/larv-design/SKILL.md
    grep -q "mode: user-specified" skills/larv-design/SKILL.md
    grep -q "mode: decide-later" skills/larv-design/SKILL.md
    grep -q "without re-asking" skills/larv-design/SKILL.md
}

@test "larv-domain SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-domain/SKILL.md
    grep -q "medium.com/@harryespant" skills/larv-domain/SKILL.md
    grep -qi "viability" skills/larv-domain/SKILL.md
}

@test "larv-design SKILL.md is no longer a stub" {
    ! grep -q "STUB — sub-project A scaffolding only" skills/larv-design/SKILL.md
    ! grep -q "getdesign.md" skills/larv-design/SKILL.md
    grep -q "Attio" skills/larv-design/SKILL.md
    grep -q "allocate_port mockup" skills/larv-design/SKILL.md
    grep -q "Which public VM port do you want for the mockup server" skills/larv-design/SKILL.md
    grep -q "requested_mockup_port" skills/larv-design/SKILL.md
    grep -qi "probe-before-announce" skills/larv-design/SKILL.md
    grep -q "attio-venture-html-effectiveness/" skills/larv-design/SKILL.md
    grep -q "templates/attio-crm-workspace.html" skills/larv-design/SKILL.md
    grep -q "visual-implementation-contract.md" skills/larv-design/SKILL.md
    grep -q "forbidden generic defaults" skills/larv-design/SKILL.md
    grep -q "route-to-mockup parity matrix" skills/larv-design/SKILL.md
    grep -q "same visual output as the chosen mockups" skills/larv-design/SKILL.md
    grep -q "app logo" skills/larv-design/SKILL.md
    grep -q "URL logo" skills/larv-design/SKILL.md
    grep -q 'rel="icon"' skills/larv-design/SKILL.md
    grep -q "apple-touch-icon" skills/larv-design/SKILL.md
    grep -q "interactive HTML Effectiveness" skills/larv-design/SKILL.md
    grep -q "clickable navigation harness" skills/larv-design/SKILL.md
    grep -q "interaction-map.md" skills/larv-design/SKILL.md
    grep -q "static-only mockups" skills/larv-design/SKILL.md
}

@test "larv-design exposes the bundled HTML effectiveness galleries as design sources" {
    grep -q "Design Choice System" skills/larv-design/SKILL.md
    grep -q "single source of truth" skills/larv-design/SKILL.md
    grep -q "Custom" skills/larv-design/SKILL.md
    grep -q "Attio Finance" skills/larv-design/SKILL.md
    grep -q "Attio Venture" skills/larv-design/SKILL.md
    grep -q "attio-venture-html-effectiveness/" skills/larv-design/SKILL.md
    grep -q "attio-finance-html-effectiveness-design/" skills/larv-design/SKILL.md
    grep -q "attio-venture-html-effectiveness-design/" skills/larv-design/SKILL.md
    grep -q "templates/attio-crm-workspace.html" skills/larv-design/SKILL.md
    grep -q "21-credit-officer-crm.html" skills/larv-design/SKILL.md
    grep -q "22-sales-crm.html" skills/larv-design/SKILL.md
    grep -q "23-service-crm.html" skills/larv-design/SKILL.md
    grep -q "visual brainstorm" skills/larv-design/SKILL.md
    grep -q "mockup template" skills/larv-design/SKILL.md
    grep -q "HTML/CSS/JavaScript patterns" skills/larv-design/SKILL.md
    grep -q "CRM interaction patterns" skills/larv-design/SKILL.md
    grep -q "source_path: attio-venture-html-effectiveness" skills/larv-design/SKILL.md
    grep -q "templates/attio-crm-workspace.html.*first recommendation" skills/larv-design/SKILL.md
    grep -q "attio plus recommendations" skills/larv-design/SKILL.md
    grep -q "Do not force the user to pick three designs" skills/larv-design/SKILL.md
}

@test "larv-design no longer asks users to browse external design galleries" {
    ! grep -q "WebFetch" skills/larv-design/SKILL.md
    ! grep -q "external getdesign" skills/larv-design/SKILL.md
    ! grep -q "at least 3 picks" skills/larv-design/SKILL.md
    grep -q "Do not require any external inspiration site" skills/larv-design/SKILL.md
    grep -q "Do not ask the user to browse external inspiration sites" skills/larv-design/SKILL.md
}

@test "larv-design makes mockup URL a mandatory completion gate" {
    grep -q "Mandatory completion gate" skills/larv-design/SKILL.md
    grep -q "mockup_url" skills/larv-design/SKILL.md
    grep -q "status: failed" skills/larv-design/SKILL.md
    grep -q "Do not proceed to brand finalization" skills/larv-design/SKILL.md
    grep -q "mockup_url: \"http://sandbox.example.com:<port>/\"" skills/larv-design/SKILL.md
    grep -q "static_server_check_remote_deps" skills/larv-design/SKILL.md
    grep -q "runtime_gate_require_phase_url . design" skills/larv-design/SKILL.md
    grep -q "mockups_dir" skills/larv-design/SKILL.md
    ! grep -q "/srv/larv/.*/mockups" skills/larv-design/SKILL.md
    grep -q "static_server_open_firewall" skills/larv-design/SKILL.md
    grep -q "refusing to announce local-only mockup URL" skills/larv-design/SKILL.md
    grep -q "http://sandbox.example.com:<port>/" skills/larv-design/SKILL.md
    grep -q "click-through smoke check" skills/larv-design/SKILL.md
    grep -q "broken links" skills/larv-design/SKILL.md
}

@test "larv-docsite SKILL.md exists for Phase 6.5" {
    [ -f skills/larv-docsite/SKILL.md ]
    grep -q "^name: larv-docsite" skills/larv-docsite/SKILL.md
    grep -q "Phase 6.5" skills/larv-docsite/SKILL.md
    grep -q "allocate_port docsite" skills/larv-docsite/SKILL.md
    grep -q "Which public VM port do you want for the docs site" skills/larv-docsite/SKILL.md
    grep -q "requested_docsite_port" skills/larv-docsite/SKILL.md
    grep -q "Docsify" skills/larv-docsite/SKILL.md
}

@test "larv-docsite makes docsite URL a mandatory completion gate" {
    grep -q "Mandatory completion gate" skills/larv-docsite/SKILL.md
    grep -q "docsite_url" skills/larv-docsite/SKILL.md
    grep -q "status: failed" skills/larv-docsite/SKILL.md
    grep -q "docsite_url: \"http://sandbox.example.com:<port>/\"" skills/larv-docsite/SKILL.md
    grep -q "static_server_check_remote_deps" skills/larv-docsite/SKILL.md
    grep -q "runtime_gate_require_phase_url . docsite" skills/larv-docsite/SKILL.md
    grep -q "docs/Handsoff.md" skills/larv-docsite/SKILL.md
    grep -q "docs/Handsoff/" skills/larv-docsite/SKILL.md
    grep -q "docs/user-manual/" skills/larv-docsite/SKILL.md
    grep -q "DOCS.md" skills/larv-docsite/SKILL.md
    grep -q "user-manual/seed-data.md" skills/larv-docsite/SKILL.md
    grep -q "README.md" skills/larv-docsite/SKILL.md
    grep -q "_sidebar.md" skills/larv-docsite/SKILL.md
    grep -q "https://cdn.jsdelivr.net/npm/docsify@4" skills/larv-docsite/SKILL.md
    grep -q "homepage: 'README.md'" skills/larv-docsite/SKILL.md
    grep -q "docsite_root=\"/tmp/larv-" skills/larv-docsite/SKILL.md
    ! grep -q "/srv/larv/.*/docsite" skills/larv-docsite/SKILL.md
    grep -q "static_server_open_firewall" skills/larv-docsite/SKILL.md
    grep -q "refusing to announce local-only doc-site URL" skills/larv-docsite/SKILL.md
    grep -q "http://sandbox.example.com:<port>/" skills/larv-docsite/SKILL.md
}

@test "larv-provision redirects active sandbox startup to handoff bootstrap" {
    grep -q "Do not dispatch this during" skills/larv-provision/SKILL.md
    grep -q "app sandbox belongs to implementation handoff" skills/larv-provision/SKILL.md
    grep -q "docs/Handsoff/bootstrap-sandbox.md" skills/larv-provision/SKILL.md
    grep -q "Create a bare Laravel scaffold" skills/larv-provision/SKILL.md
    grep -q "Print the sandbox URL only after both probes pass" skills/larv-provision/SKILL.md
    grep -q "not from larv-provision during /larv:full" skills/larv-provision/SKILL.md
}

@test "larv-plan requires deploy-sandbox script for handoff bootstrap" {
    grep -q "deploy-sandbox.sh" skills/larv-plan/SKILL.md
    grep -q "executable" skills/larv-plan/SKILL.md
    grep -q "APP_PORT" skills/larv-plan/SKILL.md
    grep -q "DB_DATABASE" skills/larv-plan/SKILL.md
    grep -q "LARV_APP_PID_FILE" skills/larv-plan/SKILL.md
    grep -q "setsid bash" skills/larv-plan/SKILL.md
    grep -q "without muxplex-visible tmux sessions" skills/larv-plan/SKILL.md
    grep -q "Handoff bootstrap refuses" skills/larv-plan/SKILL.md
    grep -q "bare Laravel scaffold" skills/larv-plan/SKILL.md
    grep -q "rerun docs/Handsoff/bootstrap-sandbox.md" skills/larv-plan/SKILL.md
    grep -q "at least 10 realistic records" skills/larv-plan/SKILL.md
    grep -q "php artisan db:seed --force" skills/larv-plan/SKILL.md
    grep -q "multiple focused seeders" skills/larv-plan/SKILL.md
    grep -q "seeded test credentials" skills/larv-plan/SKILL.md
    grep -q "normal login screen" skills/larv-plan/SKILL.md
    ! grep -q "User Switcher" skills/larv-plan/SKILL.md
    ! grep -q "DEMO_MODE" skills/larv-plan/SKILL.md
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
    grep -q "creates the bare Laravel scaffold" skills/larv-implement/SKILL.md
    grep -q "auto-all" skills/larv-implement/SKILL.md
    grep -q "manual-slice" skills/larv-implement/SKILL.md
    grep -q "docs/user-manual/testing" skills/larv-implement/SKILL.md
    grep -q "docs/user-manual/seed-data.md" skills/larv-implement/SKILL.md
    grep -q "docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT" skills/larv-implement/SKILL.md
    grep -q "never write implementation reports at the project root" skills/larv-implement/SKILL.md
    grep -q "visual-implementation-contract.md" skills/larv-implement/SKILL.md
    grep -q "desktop and mobile screenshots" skills/larv-implement/SKILL.md
    grep -q "visual source of truth" skills/larv-implement/SKILL.md
    grep -q "docs/larv/08-implementation/screenshots/<slice-id>/" skills/larv-implement/SKILL.md
    grep -q "test credentials for every role/persona" skills/larv-implement/SKILL.md
    grep -q "permissions scopes" skills/larv-implement/SKILL.md
    ! grep -q "User Switcher" skills/larv-implement/SKILL.md
    ! grep -q "DEMO_MODE" skills/larv-implement/SKILL.md
}

@test "larv-handoff renders production and user guide documents" {
    grep -q "handsoff_render_runtime_guides" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/production-deploy.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/env-guide.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/operations-guide.md" skills/larv-handoff/SKILL.md
    grep -q "docs/Handsoff/package-guide.md" skills/larv-handoff/SKILL.md
    grep -q "docs/user-manual/README.md" skills/larv-handoff/SKILL.md
    grep -q "docs/user-manual/seed-data.md" skills/larv-handoff/SKILL.md
    grep -q "visual-implementation-contract" skills/larv-handoff/SKILL.md
    grep -q "docs/larv/03-design/mockups/" skills/larv-handoff/SKILL.md
    grep -q "DOCS.md" skills/larv-handoff/SKILL.md
    grep -q "docs/larv/08-implementation/reports/" skills/larv-handoff/SKILL.md
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
    grep -q "Browser flow and mockup parity verification" skills/larv-verify/SKILL.md
    grep -q "Visit every planned user-facing page" skills/larv-verify/SKILL.md
    grep -q "Sign in with every seeded credential" skills/larv-verify/SKILL.md
    grep -q "Compare implemented UI against approved mockups" skills/larv-verify/SKILL.md
    grep -q "Approved mockups are the final UI contract" skills/larv-verify/SKILL.md
    grep -q "Do not return \`status: complete\` if any planned page/flow is untested" skills/larv-verify/SKILL.md
    grep -q "Source-code and plan parity verification" skills/larv-verify/SKILL.md
    grep -q "requirements traceability matrix" skills/larv-verify/SKILL.md
    grep -q "Do not return \`status: complete\` if any PRD requirement" skills/larv-verify/SKILL.md
    grep -q "Single-layout and Filament verification" skills/larv-verify/SKILL.md
    grep -q "policy-app pattern" skills/larv-verify/SKILL.md
    grep -q "admin views should extend the same main layout" skills/larv-verify/SKILL.md
    grep -q "admin routes use the same shell as the main route" skills/larv-verify/SKILL.md
}

@test "phase prompts reference required bundled skills" {
    grep -q "bundle/domain-driven-design" skills/larv-domain/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-c4-architecture" skills/larv-architecture/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-test-strategy" skills/larv-tests/SKILL.md
    grep -q "bundle/masterplan/skills/masterplan-bug-premortem" skills/larv-premortem/SKILL.md
    grep -q "bundle/superpowers-laravel/skills" skills/larv-implement/SKILL.md
    grep -q "attio-venture-html-effectiveness/" skills/larv-design/SKILL.md
    grep -q "templates/attio-crm-workspace.html" skills/larv-design/SKILL.md
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
    grep -q "docs/larv/08-implementation/reports/" skills/larv-learn/SKILL.md
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

@test "impeccable-higgsfield redesign skill enforces cost, privacy and full-screen rules" {
    f=skills/larv-redesign-impeccable-higgsfield/SKILL.md
    grep -q "/larv:redesign-impeccable-higgsfield" "$f"
    grep -q "production app redesign" "$f"
    grep -q "screen-inventory.md" "$f"
    grep -q "visual-parity.md" "$f"
    grep -q "FICTIONAL-DATA-CONFIRMED" "$f"
    grep -q "LARV_DESIGN_CONFIRMED_SPEND" "$f"
    grep -q "every screen" "$f"
    grep -q "Never run \`higgsfield auth token\`" "$f"
    grep -q "Do not ask the user to run" "$f"
}

@test "Phase 0 and Phase 3 support the impeccable-higgsfield design mode" {
    grep -q "mode: impeccable-higgsfield" skills/larv-discuss/SKILL.md
    f=skills/larv-design/SKILL.md
    grep -q "mode: impeccable-higgsfield" "$f"
    grep -q "design-directions.sh" "$f"
    grep -q "design-setup.sh check" "$f"
    grep -q "docs/larv/03-design/directions/" "$f"
    grep -q "only when the design mode is not \`impeccable-higgsfield\`" "$f"
    grep -q "one interactive HTML prototype of the picked comp" "$f"
}

@test "impeccable-higgsfield skills pass the cap, stop via the script and keep the board port separate" {
    r=skills/larv-redesign-impeccable-higgsfield/SKILL.md
    d=skills/larv-design/SKILL.md
    ! grep -q "static_server_stop" "$r"
    ! grep -q "static_server_stop" "$d"
    grep -q 'bash \$D stop "\$PWD" \$OUT' "$r"
    grep -q 'bash \$D stop "\$PWD" \$OUT' "$d"
    grep -q "LARV_HIGGSFIELD_CREDIT_CAP=" "$r"
    grep -q "LARV_HIGGSFIELD_CREDIT_CAP=<credit_cap from design-preferences.md>" "$d"
    grep -q "LARV_DESIGN_PORT_KIND=mockup-port" "$d"
    grep -q -- "--from <key> --reroll <n>" "$r"
}
