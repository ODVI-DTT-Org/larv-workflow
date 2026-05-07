#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: simulate-full.sh <project-dir> <project-name>" >&2
    exit 64
}

[ "$#" -ge 2 ] || usage
dir="$1"
name="$2"
plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
slug="$(printf "%s" "$name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
[ -n "$slug" ] || slug="larv-sim"

mkdir -p "$dir"
bash "$plugin_root/scripts/state.sh" init "$dir" "$name" greenfield
mkdir -p "$dir/docs/larv/00-discuss" "$dir/docs/larv/01-domain" "$dir/docs/larv/02-architecture" \
    "$dir/docs/larv/03-design" "$dir/docs/larv/04-test-strategy" "$dir/docs/larv/05-premortem" \
    "$dir/docs/larv/06-implementation" "$dir/docs/larv/07-runtime" "$dir/adr"

cat > "$dir/docs/larv/00-discuss/product-brief.md" <<EOF
# Product Brief

Build a loan approval system for borrowers, loan officers, analysts, approvers, and compliance reviewers.
EOF

cat > "$dir/docs/larv/00-discuss/library-decisions.md" <<'EOF'
# Library Decisions

- Filament: selected for internal review and approval operations.
- Fortify + Sanctum: selected for staff and borrower authentication.
- Horizon + Redis: selected for asynchronous document checks and notifications.
- Pulse + Telescope: selected for operational visibility.
- Cashier: deferred unless paid loan products are introduced.
- Scout: selected for application search.
EOF

cat > "$dir/docs/larv/01-domain/domain-model.md" <<'EOF'
# Domain Model

- LoanApplication
- Applicant
- DocumentRequirement
- CreditAssessment
- ApprovalDecision
- ApprovalPolicy
- AuditEvent
EOF

cat > "$dir/docs/larv/02-architecture/c4-context.md" <<'EOF'
# C4 Context

Borrowers submit applications; staff review, assess, approve, reject, and audit decisions.
EOF

cat > "$dir/docs/larv/02-architecture/package-integration-matrix.md" <<'EOF'
# Package Integration Matrix

- Filament: LoanApplicationResource, approval queue filters, policy-backed actions.
- Horizon: queued document verification and notification jobs.
- Scout: searchable loan applications and applicant search.
- Pulse/Telescope: restricted operational dashboards.
EOF

cat > "$dir/docs/larv/04-test-strategy/package-test-matrix.md" <<'EOF'
# Package Test Matrix

- Filament: resource authorization, filters, approval actions.
- Horizon: job dispatch and retry behavior.
- Scout: indexing and search filters.
EOF

cat > "$dir/docs/larv/06-implementation/elephant-carpaccio.md" <<'EOF'
# Slice Plan

## slice-01-foundation
goal: Laravel foundation, auth, and roles
depends_on: []
parallel: false

## slice-02-loan-applications
goal: Borrower loan application submission
depends_on: [slice-01-foundation]
parallel: false

## slice-03-filament-review
goal: Filament review queue and approval actions
depends_on: [slice-02-loan-applications]
parallel: false
EOF

cat > "$dir/docs/larv/07-runtime/deploy-sandbox.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${APP_PORT:?APP_PORT is required}"
: "${DB_DATABASE:?DB_DATABASE is required}"
php artisan migrate --force
php artisan serve --host=0.0.0.0 --port="$APP_PORT"
EOF
chmod +x "$dir/docs/larv/07-runtime/deploy-sandbox.sh"

(
    cd "$dir"
    . "$plugin_root/scripts/lib/handsoff.sh"
    handsoff_render_index "."
    handsoff_render_bootstrap_sandbox "."
    handsoff_render_runtime_guides "."
    handsoff_render_slice "." slice-01 foundation
    handsoff_render_starting_points "."
)

echo "Simulated /larv:full handoff for $name at $dir"
