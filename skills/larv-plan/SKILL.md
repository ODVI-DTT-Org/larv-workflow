---
name: larv-plan
description: Phase 6 - Elephant Carpaccio slice plan with parallelism annotations, token budget, and the mandatory sandbox deploy/start script consumed by Phase 7.
---

# larv-plan

Turn the approved design, architecture, and test strategy into implementation slices and write the exact sandbox deployment script that Phase 7 will run on the VM.

## Inputs

- `docs/larv/00-discuss/*.md`
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/*.md`
- `docs/larv/03-design/*.md`
- `docs/larv/04-test-strategy/*.md`
- `docs/larv/05-premortem/*.md`
- `docs/larv/STATE.yaml`

## What you do

1. Produce an Elephant Carpaccio plan in `docs/larv/06-implementation/elephant-carpaccio.md`.
2. Annotate every slice with `id`, `goal`, user-visible value, files, migrations, tests, acceptance criteria, `depends_on`, and `parallel`.
3. Produce `docs/larv/06-implementation/token-budget.md` with slice-level token/minute estimates.
4. Initialize or update `STATE.yaml.slices` with the planned slice IDs.
5. Write the executable Phase 7 deployment script at `docs/larv/07-runtime/deploy-sandbox.sh`.

## Mandatory deploy script

`docs/larv/07-runtime/deploy-sandbox.sh` is required. Phase 7 refuses to provision without it.

The script runs on the VM from the rsynced project root and must:

- Use `APP_PORT` from the environment.
- Use `DB_DATABASE` from the environment when database configuration is needed.
- Start or restart the app process so `http://127.0.0.1:$APP_PORT/` responds.
- Fail fast with useful errors (`set -euo pipefail`).
- Avoid placeholders such as `TODO`, `TBD`, or "deployment commands here".

For a normal Laravel app, use this baseline unless the architecture docs require Docker:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${APP_PORT:?APP_PORT is required}"
: "${DB_DATABASE:?DB_DATABASE is required}"

if [ ! -f artisan ]; then
    echo "ERROR: artisan not found in $(pwd); project was not rsynced correctly" >&2
    exit 1
fi

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
fi

if command -v composer >/dev/null 2>&1; then
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

php artisan key:generate --force >/dev/null 2>&1 || true
php artisan migrate --force

session="larv-app-${APP_PORT}"
tmux kill-session -t "$session" 2>/dev/null || true
tmux new-session -d -s "$session" "php artisan serve --host=0.0.0.0 --port=$APP_PORT"
tmux has-session -t "$session"
```

If Docker is required, write a Docker-specific script instead, but it must still honor `APP_PORT`, start the stack, and leave the app probeable at `127.0.0.1:$APP_PORT`.

After writing it, run:

```bash
chmod +x docs/larv/07-runtime/deploy-sandbox.sh
```

## Required outputs

- `docs/larv/06-implementation/elephant-carpaccio.md`
- `docs/larv/06-implementation/token-budget.md`
- `docs/larv/07-runtime/deploy-sandbox.sh`

## What you do not do

- Do not leave deployment as a prose instruction. Phase 7 needs an executable script.
- Do not include placeholder commands in the deploy script.
- Do not start the VM services in Phase 6. Phase 7 executes the script.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/06-implementation/elephant-carpaccio.md
  - docs/larv/06-implementation/token-budget.md
  - docs/larv/07-runtime/deploy-sandbox.sh
state_updates:
  slices: ...
plugin_improvement_notes: (none)
```
