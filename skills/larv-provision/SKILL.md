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

slug=$(yq -r .project.slug docs/larv/STATE.yaml)

# 1. Allocate
app_port=$(allocate_port app)
mockup_port=$(allocate_port mockup)
db_name=$(allocate_db "$slug")
project_root=$(allocate_project_root "$slug")

bash scripts/state.sh record-allocation . app-port "$app_port"
bash scripts/state.sh record-allocation . mockup-port "$mockup_port"
bash scripts/state.sh record-allocation . db-name "$db_name"
bash scripts/state.sh record-allocation . project-root "$project_root"

# 2. SSH to VM, scaffold project root, copy compose stack, bring it up
#    (compose template + seed scripts are in templates/sandbox/ — out of MVP scope to fill in)
ssh "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}" "mkdir -p $project_root"
# (deployment commands here)

# 3. Probe-before-announce
if probe_url_inside "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}" "$app_port" laravel; then
    if probe_with_retries "http://${LARV_VM_HOST}:${app_port}/" laravel; then
        app_url="http://${LARV_VM_HOST}:${app_port}"
    else
        echo "ERROR: external probe failed at $app_url" >&2
        return 1
    fi
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

# 6. Commit
safe_commit_docs "[larv] phase 7: provision approved (app=$app_port db=$db_name)"
```

## Probe-before-announce rule (hard requirement)

Never print a URL until both the inside probe (curl from the VM at 127.0.0.1) and the outside probe (curl from the runner at LARV_VM_HOST) succeed. Use the `laravel` profile (60s × 6) for the app, `static` (5s × 5) for static servers, `nginx` (10s × 5) for the reverse proxy.

## What you do not do

- You do not write to `docs/Handsoff/slice-*.md` — that is `larv-handoff`'s job; this skill calls into it.
- You do not pick ports manually — always go through `allocate_port`.

## Required outputs

- `docs/larv/07-runtime/sandbox-runbook.md`
- Updated allocations in `STATE.yaml.execution.allocations`
- Regenerated `docs/Handsoff.md` and AI starting-point files

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/07-runtime/sandbox-runbook.md
state_updates:
  execution.allocations: [...]
  sandbox.app_url: "http://31.220.79.31:<port>"
  sandbox.status: provisioned
plugin_improvement_notes: (none)
```
