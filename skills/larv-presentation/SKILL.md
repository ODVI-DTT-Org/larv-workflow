---
name: larv-presentation
description: Use when the user types /larv:presentation or asks for a browser-served visual workflow presentation of the current repo.
---

# larv-presentation

Generate and serve a visual role workflow presentation for the current repository.

## What you do

Run from the larv plugin root:

```bash
bash scripts/presentation.sh "$PWD" start "$ARGUMENTS"
```

If the runtime environment resolves command paths differently, use the absolute plugin script path and pass the user's current project directory as the first argument. If `$ARGUMENTS` is not available, pass the words after `/larv:presentation` as the optional focus string.

## Focus Arguments

The command supports optional focus text:

- `/larv:presentation` - whole-repo role workflow
- `/larv:presentation skills visual representation` - plugin skills/commands/scripts/gates/install-target map
- `/larv:presentation dataflow <feature>` - dataflow map for a specific feature
- `/larv:presentation feature <name>` - feature workflow map

Do not ask for clarification if the focus contains `skills`, `dataflow`, or `feature`; use that mode directly.

## Contract

- Read the whole repo, not only `docs/larv/`.
- Include `docs/larv/`, `docs/user-manual/`, `DOCS.md`, `README.md`, routes, models, views, Filament resources, tests, and mockup references when present.
- Infer the workflow for every detected role/persona from docs, code, routes, tests, seed guides, and testing guides.
- When a focus is provided, filter and title the presentation around that focus while still scanning the whole repo for supporting evidence.
- Use an HTML Effectiveness / Attio-style app presentation design, not a plain markdown index.
- Generate the artifact under `docs/larv/presentation/index.html` when the project has `docs/larv/`; otherwise use `.larv/presentation/index.html`.
- Also generate visual graph artifacts under `docs/larv/presentation/visual-workflow/` or `.larv/presentation/visual-workflow/`:
  - `data-flow-graph.html` as a core business database table flowchart: routes, domain tables, core foreign-key data movement, validation, state rules, and report outputs. Its Business logic and write rules Mermaid diagram must analyze backend code and the database schema to show detected CREATE, UPDATE, and DELETE flows into core business tables. Exclude logs, histories, snapshots, sessions, cache, jobs, and other infrastructure tables from the visual data-flow graph.
  - `user-flow-graph.html` as role/persona demo, training, and go-live wizard steppers showing what each user role does.
  - `complete-workflow-graph.html` for the full go-live visual workflow tying role steppers, runtime entry points, data changes, mockups, and verification evidence together.
  - `index.html` as the graph hub.
- Serve only on public VM ports `2000-2999`.
- Open the local firewall when possible.
- Probe inside the VM and against the external URL before announcing.
- Print the external URL as `http://sandbox.example.com:<port>/`, never `127.0.0.1` or `localhost`.

## Optional Port

If the user requests a specific port, set:

```bash
LARV_PRESENTATION_PORT=<2000-2999> bash scripts/presentation.sh "$PWD" start
```

Reject ports outside `2000-2999`. If the requested port is occupied, stop and ask the user for a different port.

## What You Do Not Do

- Do not start the presentation on ports outside `2000-2999`.
- Do not SSH to the VM; assume the command is running inside the sandbox VM.
- Do not announce the URL until probes pass.
- Do not replace the app sandbox, docs, or mockup servers. This is a separate presentation server.
