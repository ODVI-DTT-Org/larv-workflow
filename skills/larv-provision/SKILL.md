---
name: larv-provision
description: Phase 7 — verifier-driven port/DB/project allocation, Docker compose deploy, probe-before-announce, runbook generation, and AI starting-point regeneration.
---

# larv-provision

Allocate VM resources for this project, deploy the Docker compose stack, verify every service responds before printing URLs, and regenerate the handsoff documents (so they reflect runtime info before the Phase 8 routing menu).

## Inputs

- `docs/larv/STATE.yaml`
- `docs/larv/02-architecture/library-pins.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`

## What you do

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/probe.sh
. scripts/lib/handsoff.sh
. scripts/lib/git_safe.sh
. scripts/lib/runtime_gate.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"

# 1. Allocate
app_port=$(allocate_port app)
mockup_port=$(allocate_port mockup)
db_name=$(allocate_db "$slug")
project_root=$(allocate_project_root "$slug")

bash scripts/state.sh record-allocation . app-port "$app_port"
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
bash scripts/state.sh record-allocation . db-name "$db_name"
bash scripts/state.sh record-allocation . project-root "$project_root"

# 2. SSH to VM, scaffold project root, copy the project, and start the sandbox
if [ ! -x docs/larv/07-runtime/deploy-sandbox.sh ]; then
    echo "ERROR: missing executable docs/larv/07-runtime/deploy-sandbox.sh" >&2
    echo "Phase 6 must write the exact sandbox deploy/start script before provisioning." >&2
    exit 1
fi
ssh "$ssh_target" "mkdir -p $project_root"
rsync -avz --delete --exclude .git --exclude docs/larv/07-runtime/sandbox-url.txt ./ "$ssh_target:$project_root/app/"
ssh "$ssh_target" "cd $project_root/app && APP_PORT=$app_port DB_DATABASE=$db_name bash docs/larv/07-runtime/deploy-sandbox.sh"

# 3. Probe-before-announce — both inside and outside must succeed.
# §3.3 hard rule: do NOT set app_url until both probes pass.
if ! probe_url_inside "$ssh_target" "$app_port" laravel; then
    echo "ERROR: inside-VM probe failed for app port $app_port" >&2
    exit 1
fi
app_url="http://${LARV_VM_HOST}:${app_port}/"
if ! probe_with_retries "$app_url" laravel; then
    echo "ERROR: external probe failed at $app_url" >&2
    exit 1
fi

# 4. Regenerate handsoff (now with allocated values inlined)
handsoff_render_index .
# (regenerate slice handsoffs here)
handsoff_render_starting_points .

# 5. Write runbook
mkdir -p docs/larv/07-runtime
cat > docs/larv/07-runtime/sandbox-runbook.md <<EOF
# Sandbox Runbook — $slug

App URL: $app_url
DB: $db_name
Project root: $project_root
SSH: ssh ${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}
EOF
printf "%s\n" "$app_url" > docs/larv/07-runtime/sandbox-url.txt
runtime_gate_require_phase_url . sandbox "$LARV_VM_HOST"
bash scripts/state.sh update . ".sandbox.app_url = \"$app_url\" | .sandbox.status = \"provisioned\""
echo "Sandbox ready at $app_url"

# 6. Commit
safe_commit_docs "[larv] phase 7: provision approved (app=$app_port db=$db_name)"
```

## Mandatory completion gate

The app sandbox is not optional. Do not call `safe_commit_docs`, regenerate final handsoff as complete, open the Phase 8 routing menu, or return `status: complete` until all of these are true:

- `app_port`, `db_name`, and `project_root` were allocated through verifier helpers and recorded in `STATE.yaml.execution.allocations`.
- The project root exists on the VM.
- `docs/larv/07-runtime/deploy-sandbox.sh` exists, is executable, and was run on the VM with `APP_PORT` and `DB_DATABASE`.
- The Laravel app stack was actually started on the VM. Placeholder, missing deploy script, or skipped deployment commands are a failed phase.
- `probe_url_inside "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}" "$app_port" laravel` succeeded.
- `probe_with_retries "$app_url" laravel` succeeded.
- `docs/larv/07-runtime/sandbox-runbook.md` exists and includes `App URL: $app_url`.
- `docs/larv/07-runtime/sandbox-url.txt` exists and contains the external URL.
- `STATE.yaml.sandbox.app_url` and `STATE.yaml.sandbox.status` are updated.
- `runtime_gate_require_phase_url . sandbox "$LARV_VM_HOST"` succeeded.
- The URL was printed to the user.

If any item fails or cannot be performed, stop immediately and return:

```yaml
status: failed
sandbox_url: null
errors_unresolved:
  - "Phase 7 sandbox app was not started and probe-confirmed."
```

## Probe-before-announce rule (hard requirement)

Never print a URL until both the inside probe (curl from the VM at 127.0.0.1) and the outside probe (curl from the runner at LARV_VM_HOST) succeed. Use the `laravel` profile (60s × 6) for the app, `static` (5s × 5) for static servers, `nginx` (10s × 5) for the reverse proxy.

## What you do not do

- You do not write to `docs/Handsoff/slice-*.md` — that is `larv-handoff`'s job; this skill calls into it.
- You do not pick ports manually — always go through `allocate_port`.

## Required outputs

- `docs/larv/07-runtime/sandbox-runbook.md`
- `docs/larv/07-runtime/sandbox-url.txt`
- Updated allocations in `STATE.yaml.execution.allocations`
- Regenerated `docs/Handsoff.md` and AI starting-point files

## Subagent return contract

```yaml
status: complete
sandbox_url: "http://31.220.79.31:<port>/"
files_written:
  - docs/larv/07-runtime/sandbox-runbook.md
  - docs/larv/07-runtime/sandbox-url.txt
state_updates:
  execution.allocations: [...]
  sandbox.app_url: "http://31.220.79.31:<port>/"
  sandbox.status: provisioned
plugin_improvement_notes: (none)
```
