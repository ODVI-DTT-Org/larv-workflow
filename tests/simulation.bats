#!/usr/bin/env bats

load helpers

@test "dry-run simulation generates loan approval handoff surface" {
    TMP="$(setup_tmp_project)"
    run bash scripts/simulate-full.sh "$TMP" "loan approval system"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/00-discuss/library-decisions.md" ]
    [ -f "$TMP/docs/larv/02-architecture/package-integration-matrix.md" ]
    [ -f "$TMP/docs/larv/04-test-strategy/package-test-matrix.md" ]
    [ -f "$TMP/docs/larv/06-implementation/elephant-carpaccio.md" ]
    [ -f "$TMP/docs/Handsoff.md" ]
    [ -f "$TMP/docs/Handsoff/bootstrap-sandbox.md" ]
    [ -f "$TMP/docs/Handsoff/package-guide.md" ]
    [ -f "$TMP/docs/Handsoff/production-deploy.md" ]
    grep -q "LoanApplication" "$TMP/docs/larv/01-domain/domain-model.md"
    grep -q "Filament" "$TMP/docs/Handsoff/package-guide.md"
    grep -q "Horizon" "$TMP/docs/larv/02-architecture/package-integration-matrix.md"
    grep -q "slice-01-foundation" "$TMP/docs/larv/06-implementation/elephant-carpaccio.md"
    grep -q "loan-approval-system-" "$TMP/docs/Handsoff.md"
    ! grep -q "loan approval system-" "$TMP/docs/Handsoff/bootstrap-sandbox.md"
    grep -q "cd $TMP" "$TMP/docs/Handsoff/slice-01-foundation.md"
    teardown_tmp_project "$TMP"
}
