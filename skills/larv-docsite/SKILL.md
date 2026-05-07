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
project_root="$(pwd -P)"
docsite_root="/tmp/larv-$slug-docsite"
if ! static_server_check_remote_deps "$ssh_target"; then
    echo "ERROR: runtime missing required static-server tools: php, tmux, curl, or ss" >&2
    exit 1
fi

# 1. Allocate port from docsite range (9500-9999)
docsite_port=$(allocate_port docsite "$slug")
bash scripts/state.sh record-allocation . docsite-port "$docsite_port"
trap 'release_port_reservation docsite "$docsite_port" "$slug" || true' EXIT
if ! static_server_open_firewall "$ssh_target" "$docsite_port"; then
    echo "ERROR: firewall rule for doc-site port $docsite_port was not confirmed" >&2
    exit 1
fi

# 2. Stage docs/larv plus generated handoff docs and a Docsify index.html on the local VM
rm -rf "$docsite_root"
mkdir -p "$docsite_root"
if command -v rsync >/dev/null; then
    rsync -a docs/larv/ "$docsite_root/"
    rsync -a docs/Handsoff.md "$docsite_root/Handsoff.md"
    rsync -a docs/Handsoff/ "$docsite_root/Handsoff/"
else
    cp -R docs/larv/. "$docsite_root/"
    cp docs/Handsoff.md "$docsite_root/Handsoff.md"
    mkdir -p "$docsite_root/Handsoff"
    cp -R docs/Handsoff/. "$docsite_root/Handsoff/"
fi
cat > "$docsite_root/index.html" <<'HTML'
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
if ! verify_allocation "$docsite_port" docsite "$slug"; then
    echo "ERROR: doc-site port $docsite_port was taken before server start" >&2
    exit 1
fi
static_server_start "$ssh_target" "$docsite_port" "$docsite_root" \
    "larv-docsite-$slug"

# 4. Probe-before-announce
if ! probe_url_inside "$ssh_target" "$docsite_port" static; then
    echo "ERROR: inside-VM probe failed for docsite port" >&2
    exit 1
fi
docsite_url="$(static_server_url "$docsite_port")/"
case "$docsite_url" in
    http://127.0.0.1:*|http://localhost:*)
        echo "ERROR: refusing to announce local-only doc-site URL: $docsite_url" >&2
        exit 1
        ;;
esac
if ! probe_with_retries "$docsite_url" static; then
    echo "ERROR: external probe failed" >&2
    exit 1
fi
release_port_reservation docsite "$docsite_port" "$slug" || true
trap - EXIT

# 5. Announce
printf "%s\n" "$docsite_url" > docs/larv/docsite-url.txt
runtime_gate_require_phase_url . docsite "$LARV_VM_HOST"
echo "Plan available for review at $docsite_url"
```

## Mandatory completion gate

The doc-site server is not optional. Do not advance to the Phase 8 routing menu, auto-commit, or return `status: complete` until all of these are true:

- `docsite_port` was allocated through `allocate_port docsite "$slug"` and recorded as `docsite-port` in `STATE.yaml.execution.allocations`.
- `verify_allocation "$docsite_port" docsite "$slug"` succeeded immediately before server start.
- `static_server_check_remote_deps "$ssh_target"` passed for `php`, `tmux`, `curl`, and `ss` on the local VM runtime.
- `static_server_open_firewall "$ssh_target" "$docsite_port"` succeeded or no local `ufw` is installed.
- `docs/larv/` was copied to `$docsite_root` on the local VM.
- `docs/Handsoff.md` and `docs/Handsoff/` were copied to `$docsite_root` on the local VM.
- Docsify `index.html` was written on the local VM.
- `static_server_start` succeeded.
- `probe_url_inside "$ssh_target" "$docsite_port" static` succeeded.
- `probe_with_retries "$docsite_url" static` succeeded.
- `release_port_reservation docsite "$docsite_port" "$slug"` ran after the server bound and probes succeeded.
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
- Do not announce `127.0.0.1` or `localhost`; always print the external URL `http://31.220.79.31:<port>/`.
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
