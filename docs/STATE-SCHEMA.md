# STATE.yaml Schema v1

The canonical schema for `docs/larv/STATE.yaml`. Authoritative version: `schema_version: 1`.

See the shell design spec section 9 for the full structure. Examples live in `tests/fixtures/state-*.yaml`.

## Required Top-Level Keys

- `schema_version`
- `project`
- `plugin`
- `token_optimizer`
- `phase`
- `gates`
- `slices`
- `sandbox`
- `budget`
- `learn`
- `errors_unresolved`
- `policies`
- `execution`

## Mode Values

- `greenfield`
- `adopted`

`execution.caveman_style` values are also tracked:

- `null` — resolves to strict `full`
- `full` — default strict Caveman mode
- `lite`
- `ultra`
- `normal` (legacy value; resolves to `full`)
- `off` (legacy value; resolves to `full`)

## Token Optimizer Values

`token_optimizer.selected` is either `lean-ctx`, `headroom`, or `none`.
`token_optimizer.status` is `safe` only after `scripts/token-optimizer.sh` verifies
the approved version, binary hash, install path, and safe-mode environment.
All other values are fallback states and larv must continue without an optimizer.

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
