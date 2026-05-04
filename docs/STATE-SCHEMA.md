# STATE.yaml Schema v1

The canonical schema for `docs/larv/STATE.yaml`. Authoritative version: `schema_version: 1`.

See the shell design spec section 9 for the full structure. Examples live in `tests/fixtures/state-*.yaml`.

## Required Top-Level Keys

- `schema_version`
- `project`
- `plugin`
- `phase`
- `gates`
- `slices`
- `sandbox`
- `budget`
- `learn`
- `errors_unresolved`
- `policies`

## Mode Values

- `greenfield`
- `adopted`

## Cap Policy Values

- `pause_at_100pct`
- `pause_at_120pct`
- `pause_at_150pct`
- `never_pause`

## Slice State Values

- `pending`
- `in_progress`
- `completed`
- `blocked`

## Schema Migrations

See `migrations/state/` for upgrade scripts. The runner is `migrations/state/migrate.sh`.
