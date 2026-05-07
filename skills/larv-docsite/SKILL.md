---
name: larv-docsite
description: Phase 6.5 - Docsify-served review of the full plan and generated handoff before the Phase 8 routing menu. Verifier allocates a port from the docsite range; firewall opened; probe-before-announce.
---

# larv-docsite

Serve `docs/larv/` as a navigable Docsify site so the user can review the full plan in their browser before the implementation gate.

## Trigger

Runs automatically after `larv-handoff`, before the Phase 8 routing menu, so the served doc-site includes `docs/Handsoff.md`, `docs/Handsoff/bootstrap-sandbox.md`, and per-slice handoffs.

## Inputs

- All files under `docs/larv/`
- `docs/Handsoff.md`
- `docs/Handsoff/bootstrap-sandbox.md`
- `docs/Handsoff/production-deploy.md`
- `docs/Handsoff/env-guide.md`
- `docs/Handsoff/operations-guide.md`
- all files under `docs/Handsoff/`

## What you do

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/probe.sh
. scripts/lib/static_server.sh
. scripts/lib/runtime_gate.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
project_root="/srv/larv/$slug"
if ! static_server_check_remote_deps "$ssh_target"; then
    echo "ERROR: VM missing required static-server tools: php, tmux, curl, or rsync" >&2
    exit 1
fi

# 1. Allocate port from docsite range (9500-9999)
docsite_port=$(allocate_port docsite)
bash scripts/state.sh record-allocation . docsite-port "$docsite_port"
static_server_open_firewall "$ssh_target" "$docsite_port"

# 2. Stage docs/larv plus generated handoff docs and a Docsify index.html on the VM
ssh "$ssh_target" "mkdir -p $project_root/docsite"
rsync -avz docs/larv/ "$ssh_target:$project_root/docsite/"
rsync -avz docs/Handsoff.md "$ssh_target:$project_root/docsite/Handsoff.md"
rsync -avz docs/Handsoff/ "$ssh_target:$project_root/docsite/Handsoff/"
ssh "$ssh_target" "cat > $project_root/docsite/index.html" <<'HTML'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>larv plan</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css">
</head><body><div id="app">Loading...</div>
<script>
  window.$docsify = { name: 'larv plan', loadSidebar: false, search: 'auto' };
</script>
<script src="//cdn.jsdelivr.net/npm/docsify@4"></script>
<script src="//cdn.jsdelivr.net/npm/docsify@4/lib/plugins/search.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/docsify-mermaid@latest/dist/docsify-mermaid.js"></script>
<script src="//cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>mermaid.initialize({ startOnLoad: true });</script>
</body></html>
HTML

# 3. Start static server. Docsify is client-side only; static server is enough.
static_server_start "$ssh_target" "$docsite_port" "$project_root/docsite" \
    "larv-docsite-$slug"

# 4. Probe-before-announce
if ! probe_url_inside "$ssh_target" "$docsite_port" static; then
    echo "ERROR: inside-VM probe failed for docsite port" >&2
    exit 1
fi
docsite_url="$(static_server_url "$docsite_port")/"
if ! probe_with_retries "$docsite_url" static; then
    echo "ERROR: external probe failed" >&2
    exit 1
fi

# 5. Announce
printf "%s\n" "$docsite_url" > docs/larv/docsite-url.txt
runtime_gate_require_phase_url . docsite "$LARV_VM_HOST"
echo "Plan available for review at $docsite_url"
```

## Mandatory completion gate

The doc-site server is not optional. Do not advance to the Phase 8 routing menu, auto-commit, or return `status: complete` until all of these are true:

- `docsite_port` was allocated through `allocate_port docsite` and recorded as `docsite-port` in `STATE.yaml.execution.allocations`.
- `static_server_check_remote_deps "$ssh_target"` passed for `php`, `tmux`, `curl`, and `rsync`.
- `docs/larv/` was rsynced to `$project_root/docsite` on the VM.
- `docs/Handsoff.md` and `docs/Handsoff/` were rsynced to `$project_root/docsite` on the VM.
- Docsify `index.html` was written on the VM.
- `static_server_start` succeeded.
- `probe_url_inside "$ssh_target" "$docsite_port" static` succeeded.
- `probe_with_retries "$docsite_url" static` succeeded.
- `docs/larv/docsite-url.txt` exists and contains the external URL.
- `runtime_gate_require_phase_url . docsite "$LARV_VM_HOST"` succeeded.
- The URL was printed to the user.

If any item fails or cannot be performed, stop immediately and return:

```yaml
status: failed
docsite_url: null
errors_unresolved:
  - "Phase 6.5 doc-site server was not started and probe-confirmed."
```

## Server lifetime

Stays up through the Phase 8 routing menu and handoff decision. Released after the routing menu is answered, or `/larv:docsite teardown-server`.

## Required outputs

- The doc-site is browsable at `http://31.220.79.31:<port>`.
- `docs/larv/docsite-url.txt` contains the announced URL.
- `STATE.yaml.execution.allocations` includes a `docsite-port` entry.

## What you do not do

- Do not modify any `docs/larv/` content. This skill is read-only on the plan.
- Do not announce the URL until both probes succeed.
- Do not mark Phase 6.5 complete without a probe-confirmed `docsite_url`.
- Do not require the user to install anything on their machine. The doc-site loads Docsify from CDN in their browser.

## Subagent return contract

```yaml
status: complete
docsite_url: "http://31.220.79.31:<port>/"
files_written:
  - docs/larv/docsite-url.txt
state_updates:
  execution.allocations: [..., { kind: docsite-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
