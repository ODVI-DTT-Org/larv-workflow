#!/usr/bin/env bats

load helpers

setup() {
    TMP="$(setup_tmp_project)"
}
teardown() { teardown_tmp_project "$TMP"; }

@test "tracker_init creates implementation-tracker.yaml at expected path" {
    run bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/implementation-tracker.yaml" ]
}

@test "tracker_init produces a valid YAML with schema_version: 1 and empty entries" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run yq '.schema_version' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
    run yq '.entries | length' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "0" ]
}

@test "tracker_init refuses to overwrite an existing tracker" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "already exists"
}

@test "tracker_append adds an entry with a generated ID" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' \
        'Add billing' 'Wire Cashier-Stripe' feature claude-code claude-opus-4-7 \
        'slice-07-billing' 'app/Models/Subscription.php' completed"
    [ "$status" -eq 0 ]
    run yq '.entries | length' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "1" ]
    run yq -r '.entries[0].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [[ "$output" =~ ^ENT-[0-9]{4}$ ]]
    run yq -r '.entries[0].title' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "Add billing" ]
    run yq -r '.entries[0].created_by.tool' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "claude-code" ]
}

@test "tracker_append generates monotonically-increasing IDs" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b feature t m s f completed"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' c d bug t m s f completed"
    run yq -r '.entries[0].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "ENT-0001" ]
    run yq -r '.entries[1].id' "$TMP/docs/larv/implementation-tracker.yaml"
    [ "$output" = "ENT-0002" ]
}

@test "tracker_render produces a markdown view at implementation-tracker.md" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' \
        'Add billing' 'Wire Cashier-Stripe' feature claude-code claude-opus-4-7 \
        'slice-07' 'app/Models/Subscription.php' completed"
    run bash -c "source scripts/lib/tracker.sh && tracker_render '$TMP'"
    [ "$status" -eq 0 ]
    [ -f "$TMP/docs/larv/implementation-tracker.md" ]
    grep -q "Add billing" "$TMP/docs/larv/implementation-tracker.md"
    grep -q "claude-code" "$TMP/docs/larv/implementation-tracker.md"
    grep -q "ENT-0001" "$TMP/docs/larv/implementation-tracker.md"
}

@test "tracker_append rejects an invalid type" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b NOTREAL t m s f completed"
    [ "$status" -ne 0 ]
}

@test "tracker_append rejects an invalid status" {
    bash -c "source scripts/lib/tracker.sh && tracker_init '$TMP'"
    run bash -c "source scripts/lib/tracker.sh && tracker_append '$TMP' a b feature t m s f NOTREAL"
    [ "$status" -ne 0 ]
}
