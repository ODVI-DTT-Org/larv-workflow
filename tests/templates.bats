#!/usr/bin/env bats

load helpers

TEMPLATES=(slice-handoff sandbox-runbook pre-flight project-lessons adoption-report ddd-interview-questions bootstrap-sandbox.md.tmpl production-deploy.md.tmpl env-guide.md.tmpl operations-guide.md.tmpl package-matrix.md.tmpl package-slice-snippets.md.tmpl happy-path.md.tmpl user-manual-index.md.tmpl seed-data-guide.md.tmpl docs-index.md.tmpl)

@test "all 16 templates exist" {
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
    grep -q "http://31.220.79.31:<port>" templates/happy-path.md.tmpl
    grep -q "127.0.0.1" templates/happy-path.md.tmpl
}

@test "slice-handoff has Plugin Improvement Notes section" {
    run grep -F "Plugin Improvement Notes" templates/slice-handoff.md
    [ "$status" -eq 0 ]
}

@test "sandbox-runbook documents URL, SSH, docker, firewall" {
    run grep -E "App URL|VM|Docker|Firewall" templates/sandbox-runbook.md
    [ "$status" -eq 0 ]
    grep -q "Do not SSH" templates/sandbox-runbook.md
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
    grep -q "ensure_laravel_scaffold" templates/bootstrap-sandbox.md.tmpl
    grep -q "composer create-project laravel/laravel" templates/bootstrap-sandbox.md.tmpl
    grep -q "LARV_SCAFFOLD_ON_BOOTSTRAP" templates/bootstrap-sandbox.md.tmpl
    grep -q "install_vm_packages_if_missing" templates/bootstrap-sandbox.md.tmpl
    grep -q "LARV_VM_INSTALL_MODE" templates/bootstrap-sandbox.md.tmpl
    grep -q "mikefarah/yq" templates/bootstrap-sandbox.md.tmpl
    grep -q "php-pgsql" templates/bootstrap-sandbox.md.tmpl
    grep -q "docker-compose-plugin" templates/bootstrap-sandbox.md.tmpl
    grep -q 'DB_INSTALL_MODE="${DB_INSTALL_MODE:-apt}"' templates/bootstrap-sandbox.md.tmpl
    grep -q 'DB_CONNECTION="${DB_CONNECTION:-pgsql}"' templates/bootstrap-sandbox.md.tmpl
    grep -q "PostgreSQL-only" templates/bootstrap-sandbox.md.tmpl
    grep -q "docs/larv/07-runtime/sandbox-url.txt" templates/bootstrap-sandbox.md.tmpl
    grep -q "ufw allow" templates/bootstrap-sandbox.md.tmpl
    grep -q "ufw status" templates/bootstrap-sandbox.md.tmpl
    ! grep -q "DEMO_MODE" templates/bootstrap-sandbox.md.tmpl
    grep -q "export APP_PORT DB_NAME PROJECT_ROOT APP_ROOT APP_URL APP_SESSION APP_PID_FILE" templates/bootstrap-sandbox.md.tmpl
    grep -q "setsid" templates/bootstrap-sandbox.md.tmpl
    grep -q "DB_CONNECTION" templates/bootstrap-sandbox.md.tmpl
    grep -q "createdb" templates/bootstrap-sandbox.md.tmpl
    ! grep -qi "mariadb" templates/bootstrap-sandbox.md.tmpl
    ! grep -qi "mysql" templates/bootstrap-sandbox.md.tmpl
    grep -q "DB_INSTALL_MODE" templates/bootstrap-sandbox.md.tmpl
    grep -q "Sandbox ready at" templates/bootstrap-sandbox.md.tmpl
    grep -q "LARV_RUNTIME_MODE" templates/bootstrap-sandbox.md.tmpl
    grep -q "Do not SSH" templates/bootstrap-sandbox.md.tmpl
    grep -q 'PROJECT_ROOT="$(pwd -P)"' templates/bootstrap-sandbox.md.tmpl
    grep -q 'APP_URL="http://$VM_HOST:$APP_PORT/"' templates/bootstrap-sandbox.md.tmpl
    grep -q "refusing to announce local-only URL" templates/bootstrap-sandbox.md.tmpl
    grep -q "external app probe failed" templates/bootstrap-sandbox.md.tmpl
    ! grep -q "copy the project into" templates/bootstrap-sandbox.md.tmpl
    ! grep -q "ssh -o BatchMode" templates/bootstrap-sandbox.md.tmpl
}

@test "production deploy template covers Laravel Cloud and Namecheap" {
    grep -q "Laravel Cloud" templates/production-deploy.md.tmpl
    grep -q "Namecheap" templates/production-deploy.md.tmpl
    grep -q "Ask the user" templates/production-deploy.md.tmpl
    grep -q "APP_KEY" templates/production-deploy.md.tmpl
    ! grep -q "DEMO_MODE" templates/production-deploy.md.tmpl
    grep -q "A record" templates/production-deploy.md.tmpl
}

@test "production deploy template offers guide cli api and dns automation choices" {
    grep -q "guide-only" templates/production-deploy.md.tmpl
    grep -q "Laravel Cloud CLI automation" templates/production-deploy.md.tmpl
    grep -q "Laravel Cloud API automation" templates/production-deploy.md.tmpl
    grep -q "DNS automation" templates/production-deploy.md.tmpl
    grep -q "LARAVEL_CLOUD_API_TOKEN" templates/production-deploy.md.tmpl
    grep -q "cloud auth" templates/production-deploy.md.tmpl
    grep -q "Authorization: Bearer" templates/production-deploy.md.tmpl
    grep -q "NAMECHEAP_API_KEY" templates/production-deploy.md.tmpl
    grep -q "NAMECHEAP_CLIENT_IP" templates/production-deploy.md.tmpl
}

@test "handoff and starting point templates explain fresh context continuation" {
    grep -q "Fresh session recovery" templates/handsoff-index.md.tmpl
    grep -q "first slice whose STATE status is not completed" templates/handsoff-index.md.tmpl
    grep -q "Fresh session recovery" templates/ai-starting-point.md.tmpl
    grep -q "/larv:resume" templates/ai-starting-point.md.tmpl
    grep -q "/larv:feature" templates/ai-starting-point.md.tmpl
    grep -q "execution.review_mode" templates/ai-starting-point.md.tmpl
    grep -q "auto-all" templates/handsoff-index.md.tmpl
    grep -q "manual-slice" templates/handsoff-index.md.tmpl
}

@test "env and operations guide templates cover setup values" {
    grep -q "DB_DATABASE" templates/env-guide.md.tmpl
    grep -q "DB_CONNECTION=pgsql" templates/env-guide.md.tmpl
    grep -q "DB_USERNAME" templates/env-guide.md.tmpl
    grep -q "MAIL_" templates/env-guide.md.tmpl
    grep -q "STRIPE_WEBHOOK_SECRET" templates/env-guide.md.tmpl
    grep -q "PADDLE_WEBHOOK_SECRET" templates/env-guide.md.tmpl
    grep -q "REVERB_APP_KEY" templates/env-guide.md.tmpl
    grep -q "MEILISEARCH_HOST" templates/env-guide.md.tmpl
    grep -q "TYPESENSE_API_KEY" templates/env-guide.md.tmpl
    grep -q "AWS_BUCKET" templates/env-guide.md.tmpl
    grep -q "<PROVIDER>_CLIENT_ID" templates/env-guide.md.tmpl
    grep -q "REDIS_HOST" templates/env-guide.md.tmpl
    grep -q "OCTANE_SERVER" templates/env-guide.md.tmpl
    grep -q "Install" templates/operations-guide.md.tmpl
    grep -q "Troubleshooting" templates/operations-guide.md.tmpl
    grep -q "docs/user-manual/testing" templates/operations-guide.md.tmpl
    grep -q "docs/user-manual/seed-data.md" templates/operations-guide.md.tmpl
    grep -q "migrate:fresh --seed" templates/operations-guide.md.tmpl
    grep -q "normal login" templates/env-guide.md.tmpl
    grep -q "seeded test credentials" templates/operations-guide.md.tmpl
    grep -q "email/username and password" templates/env-guide.md.tmpl
    ! grep -q "User Switcher" templates/env-guide.md.tmpl
    ! grep -q "DEMO_MODE" templates/env-guide.md.tmpl
    grep -q "AI is responsible for running Laravel commands" templates/operations-guide.md.tmpl
    grep -q "queue/Horizon/runtime restarts" templates/operations-guide.md.tmpl
    grep -q "docs/larv/07-runtime/deploy-sandbox.sh" templates/operations-guide.md.tmpl
}

@test "user manual templates cover testing and seed reset" {
    grep -q "Root documentation index" templates/user-manual-index.md.tmpl
    grep -q "Per-slice testing guides" templates/user-manual-index.md.tmpl
    grep -q "docs/larv/07-runtime/sandbox-url.txt" templates/user-manual-index.md.tmpl
    grep -q "Required Seeder Policy" templates/seed-data-guide.md.tmpl
    grep -q "at least 10 realistic records" templates/seed-data-guide.md.tmpl
    grep -q "migrate:fresh --seed" templates/seed-data-guide.md.tmpl
    grep -q "Test Credentials" templates/seed-data-guide.md.tmpl
    grep -q "multiple focused seeders" templates/seed-data-guide.md.tmpl
    grep -q "normal login" templates/seed-data-guide.md.tmpl
    grep -q "Permissions Scope" templates/seed-data-guide.md.tmpl
    ! grep -q "User Switcher" templates/seed-data-guide.md.tmpl
    ! grep -q "DEMO_MODE" templates/seed-data-guide.md.tmpl
}

@test "docs index template points AI and users to organized docs" {
    grep -q "docs/Handsoff.md" templates/docs-index.md.tmpl
    grep -q "docs/user-manual/README.md" templates/docs-index.md.tmpl
    grep -q "docs/larv/08-implementation/reports/" templates/docs-index.md.tmpl
    grep -q "docs/larv/03-design/visual-implementation-contract.md" templates/docs-index.md.tmpl
    grep -q "docs/larv/09-verification/final-report.md" templates/docs-index.md.tmpl
    grep -q "docs/larv/07-runtime/sandbox-url.txt" templates/docs-index.md.tmpl
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
