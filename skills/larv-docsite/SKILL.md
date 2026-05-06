---
name: larv-docsite
description: Phase 6.5 - Docsify-served review of the entire plan before the Phase 7 hard gate. Verifier allocates a port from the docsite range; firewall opened; probe-before-announce.
---

# larv-docsite

Serve `docs/larv/` as a navigable Docsify site so the user can review the full plan in their browser before the implementation gate.

## Trigger

Runs automatically after Phase 6 (Plan) approval, before the Phase 7 hard gate.

## Inputs

- All files under `docs/larv/`
- `docs/Handsoff.md` (if it exists at this point)

## What you do

```bash
. scripts/lib/vm.sh
. scripts/lib/verifier.sh
. scripts/lib/probe.sh
. scripts/lib/static_server.sh

slug=$(yq -r .project.slug docs/larv/STATE.yaml)
ssh_target="${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
project_root="/srv/larv/$slug"

# 1. Allocate port from docsite range (9500-9999)
docsite_port=$(allocate_port docsite)
bash scripts/state.sh record-allocation . docsite-port "$docsite_port"
static_server_open_firewall "$ssh_target" "$docsite_port"

# 2. Stage docs/ and a Docsify index.html on the VM
ssh "$ssh_target" "mkdir -p $project_root/docsite"
rsync -avz docs/larv/ "$ssh_target:$project_root/docsite/"
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
    return 1
fi
if ! probe_with_retries "$(static_server_url "$docsite_port")" static; then
    echo "ERROR: external probe failed" >&2
    return 1
fi

# 5. Announce
echo "Plan available for review at $(static_server_url "$docsite_port")"
```

## Server lifetime

Stays up through the Phase 7 hard gate. Released after the routing menu is answered, or `/larv:docsite teardown-server`.

## Required outputs

- The doc-site is browsable at `http://31.220.79.31:<port>`.
- `STATE.yaml.execution.allocations` includes a `docsite-port` entry.

## What you do not do

- Do not modify any `docs/larv/` content. This skill is read-only on the plan.
- Do not announce the URL until both probes succeed.
- Do not require the user to install anything on their machine. The doc-site loads Docsify from CDN in their browser.

## Subagent return contract

```yaml
status: complete
files_written: []
state_updates:
  execution.allocations: [..., { kind: docsite-port, value: "<port>" }]
plugin_improvement_notes: (none)
```
