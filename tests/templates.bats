#!/usr/bin/env bats

load helpers

TEMPLATES=(slice-handoff sandbox-runbook pre-flight project-lessons adoption-report ddd-interview-questions bootstrap-sandbox.md.tmpl production-deploy.md.tmpl env-guide.md.tmpl operations-guide.md.tmpl package-matrix.md.tmpl package-slice-snippets.md.tmpl happy-path.md.tmpl)

@test "all 13 templates exist" {
    for t in "${TEMPLATES[@]}"; do
        if [[ "$t" == *.tmpl ]]; then
            [ -f "templates/${t}" ] || { echo "missing templates/${t}"; return 1; }
        else
            [ -f "templates/${t}.md" ] || { echo "missing templates/${t}.md"; return 1; }
        fi
    done
}

@test "package slice snippets cover package-specific implementation slices" {
    grep -q "Filament Resource slice" templates/package-slice-snippets.md.tmpl
    grep -q "Cashier billing slice" templates/package-slice-snippets.md.tmpl
    grep -q "Horizon queue slice" templates/package-slice-snippets.md.tmpl
    grep -q "tenancy slice" templates/package-slice-snippets.md.tmpl
    grep -q "Scout search slice" templates/package-slice-snippets.md.tmpl
}

@test "happy path guide covers install full handoff codex deploy" {
    grep -q "Install" templates/happy-path.md.tmpl
    grep -q "/larv:full" templates/happy-path.md.tmpl
    grep -q "handoff" templates/happy-path.md.tmpl
    grep -q "Codex CLI" templates/happy-path.md.tmpl
    grep -q "Laravel Cloud" templates/happy-path.md.tmpl
}

@test "slice-handoff has Plugin Improvement Notes section" {
    run grep -F "Plugin Improvement Notes" templates/slice-handoff.md
    [ "$status" -eq 0 ]
}

@test "sandbox-runbook documents URL, SSH, docker, firewall" {
    run grep -E "App URL|VM|Docker|Firewall" templates/sandbox-runbook.md
    [ "$status" -eq 0 ]
}

@test "project-lessons explains [project] vs [plugin] tagging" {
    run grep -E "\[project\]|\[plugin\]" templates/project-lessons.md
    [ "$status" -eq 0 ]
}

@test "adoption-report has confidence flags guidance" {
    run grep -F "confidence" templates/adoption-report.md
    [ "$status" -eq 0 ]
}

@test "ddd interview question bank documents all required output files" {
    grep -q "business-purpose.md" templates/ddd-interview-questions.md
    grep -q "ubiquitous-language.md" templates/ddd-interview-questions.md
    grep -q "subdomain-candidates.md" templates/ddd-interview-questions.md
}

@test "bootstrap-sandbox template is self-contained and writes runtime URL" {
    grep -q "does not require the larv plugin" templates/bootstrap-sandbox.md.tmpl
    grep -q "docs/larv/07-runtime/deploy-sandbox.sh" templates/bootstrap-sandbox.md.tmpl
    grep -q "docs/larv/07-runtime/sandbox-url.txt" templates/bootstrap-sandbox.md.tmpl
    grep -q "ufw allow" templates/bootstrap-sandbox.md.tmpl
    grep -q "export APP_PORT DB_NAME PROJECT_ROOT APP_URL" templates/bootstrap-sandbox.md.tmpl
    grep -q "DB_CONNECTION" templates/bootstrap-sandbox.md.tmpl
    grep -q "createdb" templates/bootstrap-sandbox.md.tmpl
    grep -q "CREATE DATABASE" templates/bootstrap-sandbox.md.tmpl
    grep -q "DB_INSTALL_MODE" templates/bootstrap-sandbox.md.tmpl
    grep -q "Sandbox ready at" templates/bootstrap-sandbox.md.tmpl
}

@test "production deploy template covers Laravel Cloud and Namecheap" {
    grep -q "Laravel Cloud" templates/production-deploy.md.tmpl
    grep -q "Namecheap" templates/production-deploy.md.tmpl
    grep -q "Ask the user" templates/production-deploy.md.tmpl
    grep -q "APP_KEY" templates/production-deploy.md.tmpl
    grep -q "A record" templates/production-deploy.md.tmpl
}

@test "env and operations guide templates cover setup values" {
    grep -q "DB_DATABASE" templates/env-guide.md.tmpl
    grep -q "DB_USERNAME" templates/env-guide.md.tmpl
    grep -q "MAIL_" templates/env-guide.md.tmpl
    grep -q "Install" templates/operations-guide.md.tmpl
    grep -q "Troubleshooting" templates/operations-guide.md.tmpl
}

@test "package matrix template covers Laravel ecosystem package propagation" {
    grep -q "Filament" templates/package-matrix.md.tmpl
    grep -q "Sanctum" templates/package-matrix.md.tmpl
    grep -q "Fortify" templates/package-matrix.md.tmpl
    grep -q "Horizon" templates/package-matrix.md.tmpl
    grep -q "Cashier" templates/package-matrix.md.tmpl
    grep -q "Scout" templates/package-matrix.md.tmpl
    grep -q "Pulse" templates/package-matrix.md.tmpl
    grep -q "Telescope" templates/package-matrix.md.tmpl
    grep -q "Octane" templates/package-matrix.md.tmpl
    grep -q "Reverb" templates/package-matrix.md.tmpl
    grep -q "tenancy" templates/package-matrix.md.tmpl
}
