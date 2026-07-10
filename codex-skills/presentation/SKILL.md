---
name: presentation
description: Use when the user types /larv:presentation or asks for a browser-served visual workflow presentation of the current repo.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:presentation

Run the larv presentation helper for the current project:

```bash
bash <larv-plugin-root>/scripts/presentation.sh "$PWD" start "$ARGUMENTS"
```

It reads the whole repo, infers role/persona workflows from docs, code, routes, tests, seed guides, and mockups, generates an HTML Effectiveness-style presentation, and also generates visual graph pages:

- `visual-workflow/data-flow-graph.html` as a core business database flowchart with routes, domain tables, core foreign-key arrows, and a rendered Mermaid diagram that analyzes backend code plus database schema to show detected CREATE, UPDATE, and DELETE flows. It excludes logs, histories, snapshots, sessions, cache, jobs, and other infrastructure tables.
- `visual-workflow/user-flow-graph.html` as role/persona demo, training, and go-live wizard steppers showing what each user role does.
- `visual-workflow/complete-workflow-graph.html` for the current complete go-live visual workflow.

It serves only on public VM ports `2000-2999`, probes the URL, and prints `http://sandbox.example.com:<port>/`.

Focus examples:

- `/larv:presentation skills visual representation`
- `/larv:presentation dataflow loan approval`
- `/larv:presentation feature onboarding`

For an explicit port:

```bash
LARV_PRESENTATION_PORT=<2000-2999> bash <larv-plugin-root>/scripts/presentation.sh "$PWD" start "$ARGUMENTS"
```
