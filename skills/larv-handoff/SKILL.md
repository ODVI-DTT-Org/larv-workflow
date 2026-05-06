---
name: larv-handoff
description: Generate the universal Handsoff.md index, per-slice handsoffs, and AI starting-point files. Mandatory before the Phase 8 routing menu.
---

# larv-handoff

Generate the documents that every execution venue (same-session, subagents, foreign AI) reads to implement the slice plan. These are the only artifacts the implementation phase consumes.

## Inputs

- `docs/larv/STATE.yaml` (project + execution.allocations)
- `docs/larv/01-domain/*.md`
- `docs/larv/02-architecture/c4-*.md`
- `docs/larv/03-design/{brand-spec,ui-design,design-decision}.md`
- `docs/larv/06-implementation/elephant-carpaccio.md`
- `adr/*.md`
- `docs/larv/decisions.md` (ADR aggregator)

## What you do

Source the helper libraries and call them in this exact order. Do not improvise.

```bash
. scripts/lib/vm.sh
. scripts/lib/handsoff.sh
. scripts/lib/tracker.sh
. scripts/lib/git_safe.sh

# 1. Initialize the tracker if it does not exist
if [ ! -f docs/larv/implementation-tracker.yaml ]; then
    tracker_init "."
    tracker_render "."
fi

# 2. Render the Handsoff index
handsoff_render_index "."

# 3. Render per-slice handsoffs from elephant-carpaccio.md
#    For each slice id + name in the slice plan:
#      handsoff_render_slice "." "$slice_id" "$slice_slug"

# 4. Render the AI starting-point files
handsoff_render_starting_points "."

# 5. Commit (auto-commit policy)
safe_commit_docs "[larv] handsoff documents generated for $(yq -r .project.slug docs/larv/STATE.yaml)"
```

## What you do not do

- You do not invoke other skills.
- You do not write content directly to handsoff files; you call library functions.
- You do not modify files outside `docs/`, `adr/`, and the AI starting-point paths.
- You do not run probe/verifier — that is `larv-provision`'s job.

## Required outputs

- `docs/Handsoff.md`
- `docs/Handsoff/slice-NN-<name>.md` for every slice in the plan
- `docs/larv/implementation-tracker.yaml` and `.md`
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursor/rules/larv.mdc`, `.codex/AGENTS.md`

## Subagent return contract

Return:

```yaml
status: complete
files_written:
  - docs/Handsoff.md
  - docs/Handsoff/slice-NN-<name>.md  (one per slice)
  - docs/larv/implementation-tracker.yaml
  - docs/larv/implementation-tracker.md
  - CLAUDE.md
  - AGENTS.md
  - GEMINI.md
  - .cursor/rules/larv.mdc
  - .codex/AGENTS.md
state_updates: {}
plugin_improvement_notes: (none)
```
