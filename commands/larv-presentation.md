---
name: larv:presentation
description: Generate and serve a visual role workflow presentation for the current repo.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

Run: `bash scripts/presentation.sh "$PWD" start "$ARGUMENTS"` from the larv plugin root. If the platform does not expose `$ARGUMENTS`, pass the words after `/larv:presentation` as the final argument string.

The command reads the whole current repository, including `docs/larv/`, `docs/user-manual/`, routes, models, views, Filament resources, tests, and README/DOCS files. It generates an HTML Effectiveness-style visual workflow presentation plus three graph artifacts:

- roles/personas detected from product docs, seed guides, code, and tests
- primary user workflows for each role
- a core business data flow graph rendered as a database table flowchart: routes, domain tables, core foreign-key arrows, and a rendered Mermaid diagram that analyzes backend code plus database schema to show detected CREATE, UPDATE, and DELETE flows. Logs, histories, snapshots, sessions, cache, jobs, and other infrastructure tables are excluded from the visual data-flow graph.
- a user flow graph rendered as role-based demo/training/go-live wizard steppers that show what each user role does
- a complete workflow graph matching the current visual workflow across role steppers, runtime, data, design, and verification
- routes, screens, models, and verification evidence
- source files used to infer the workflow

Generated files:

- `docs/larv/presentation/index.html`
- `docs/larv/presentation/visual-workflow/index.html`
- `docs/larv/presentation/visual-workflow/data-flow-graph.html`
- `docs/larv/presentation/visual-workflow/user-flow-graph.html`
- `docs/larv/presentation/visual-workflow/complete-workflow-graph.html`

It serves the presentation at a public VM URL using only ports `2000-2999`, opens the firewall when possible, probes before announcing, and prints a URL like `http://sandbox.example.com:<port>/`.

Optional explicit port: set `LARV_PRESENTATION_PORT=<2000-2999>`. If the port is occupied, stop and ask the user for another port.

Focus examples:

- `/larv:presentation` - whole-repo role workflow
- `/larv:presentation skills visual representation` - visual map of plugin commands, skills, scripts, gates, and install targets
- `/larv:presentation dataflow loan approval` - dataflow map for a specific feature
- `/larv:presentation feature onboarding` - feature workflow map
