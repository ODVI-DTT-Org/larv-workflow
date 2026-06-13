#!/usr/bin/env bats

load helpers

@test "presentation helper builds HTML Effectiveness workflow artifact from repo signals" {
    TMP_PROJECT="$(mktemp -d)"
    trap 'rm -rf "$TMP_PROJECT"' EXIT
    mkdir -p "$TMP_PROJECT/docs/larv" "$TMP_PROJECT/docs/user-manual/testing" "$TMP_PROJECT/routes" "$TMP_PROJECT/app/Models" "$TMP_PROJECT/app/Http/Controllers" "$TMP_PROJECT/tests/Feature" "$TMP_PROJECT/database/migrations"
    cat > "$TMP_PROJECT/docs/larv/STATE.yaml" <<'YAML'
project:
  slug: loan-approval
  name: Loan Approval
YAML
    cat > "$TMP_PROJECT/README.md" <<'MD'
# Loan Approval

Roles: Borrower, Loan Officer, Credit Manager.

Workflow: Borrower submits an application. Loan Officer reviews it. Credit Manager approves or rejects it.
MD
    cat > "$TMP_PROJECT/routes/web.php" <<'PHP'
<?php
Route::get('/applications', ApplicationController::class);
Route::post('/applications/{application}/approve', ApproveApplicationController::class);
PHP
    cat > "$TMP_PROJECT/database/migrations/2026_01_01_000000_create_users_table.php" <<'PHP'
<?php
Schema::create('users');
PHP
    cat > "$TMP_PROJECT/database/migrations/2026_01_01_000001_create_applications_table.php" <<'PHP'
<?php
Schema::create('applications');
foreignId('user_id')->constrained('users');
PHP
    cat > "$TMP_PROJECT/database/migrations/2026_01_01_000002_create_audit_logs_table.php" <<'PHP'
<?php
Schema::create('audit_logs');
foreignId('application_id')->constrained('applications');
PHP
    cat > "$TMP_PROJECT/app/Models/Application.php" <<'PHP'
<?php
class Application {}
PHP
    cat > "$TMP_PROJECT/app/Http/Controllers/ApplicationController.php" <<'PHP'
<?php
class ApplicationController
{
    public function store()
    {
        Application::create(request()->validated());
    }

    public function approve(Application $application)
    {
        $application->update(['status' => 'approved']);
    }

    public function destroy(Application $application)
    {
        $application->delete();
    }
}
PHP
    touch "$TMP_PROJECT/tests/Feature/ApplicationApprovalTest.php"

    run bash scripts/presentation.sh "$TMP_PROJECT" build
    [ "$status" -eq 0 ]
    [ -f "$TMP_PROJECT/docs/larv/presentation/index.html" ]
    [ -f "$TMP_PROJECT/docs/larv/presentation/visual-workflow/index.html" ]
    [ -f "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html" ]
    [ -f "$TMP_PROJECT/docs/larv/presentation/visual-workflow/user-flow-graph.html" ]
    [ -f "$TMP_PROJECT/docs/larv/presentation/visual-workflow/complete-workflow-graph.html" ]
    grep -q "Loan Approval — Role workflow map" "$TMP_PROJECT/docs/larv/presentation/index.html"
    grep -q "Borrower" "$TMP_PROJECT/docs/larv/presentation/index.html"
    grep -q "/applications" "$TMP_PROJECT/docs/larv/presentation/index.html"
    grep -q "HTML Effectiveness" "$TMP_PROJECT/docs/larv/presentation/index.html"
    grep -q "data flow graph" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "Core business table flowchart" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "applications" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    ! grep -q "audit_logs" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "users -&gt; applications via user_id" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "Rendered Mermaid diagram" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "flowchart TD" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "generated from backend code and the database schema" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "CREATE applications" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "UPDATE applications" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "DELETE applications" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    ! grep -Fq "&quot;" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    ! grep -Fq '\\"' "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    ! grep -q "mermaid-code" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
    grep -q "user flow graph" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/user-flow-graph.html"
    grep -q "Role demo wizards" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/user-flow-graph.html"
    grep -q "Enter Borrower workspace" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/user-flow-graph.html"
    grep -q "complete workflow graph" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/complete-workflow-graph.html"

    run bash scripts/presentation.sh "$TMP_PROJECT" build "dataflow loan approval"
    [ "$status" -eq 0 ]
    grep -q "Dataflow: dataflow loan approval" "$TMP_PROJECT/docs/larv/presentation/index.html"
    grep -q "Core business table flowchart" "$TMP_PROJECT/docs/larv/presentation/visual-workflow/data-flow-graph.html"
}

@test "presentation helper and verifier reserve only presentation ports 2000-2999" {
    grep -q "presentation) lo=2000; hi=2999" scripts/lib/verifier.sh
    grep -q "LARV_PRESENTATION_PORT must be in 2000-2999" scripts/presentation.sh
    grep -q "allocate_port presentation" scripts/presentation.sh
    grep -q "static_server_url" scripts/presentation.sh
}
