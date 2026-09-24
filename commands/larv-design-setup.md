---
name: larv:design-setup
description: Check or install the shared Impeccable + Higgsfield design tools used by /larv:redesign-impeccable-higgsfield and the Phase 3 impeccable-higgsfield mode.
---

## larv Headroom Combo

For every developer prompt in a larv-managed project, the global prompt preflight runs `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run `bash <larv-plugin-root>/scripts/design-setup.sh check "$PWD"` and show the result.

- Exit 0: ready. Say so.
- Exit 3 or 1: run `bash <larv-plugin-root>/scripts/design-setup.sh install`, then `check` again.
- If Higgsfield is installed but not signed in, the sign-in is the user's step. Tell them to type `! ~/.local/share/larv/higgsfield/higgsfield auth login` (no `--port`). On a headless server: open the `https://clerk.higgsfield.ai/oauth/authorize…` link from the printed file in their own browser, then deliver the failed `http://localhost:<port>/callback?...` URL to the waiting CLI with `curl` on the server. Never run `higgsfield auth token`.
- On the shared claude-team server the tools are preinstalled and signed in as dtt@oakdriveventures.com; `check` should already pass.
