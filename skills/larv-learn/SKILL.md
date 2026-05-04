---
name: larv-learn
description: Phase 11 + on-demand. Aggregate Plugin Improvement Notes; propose plugin edits via PR.
---

# larv-learn

> **STUB — sub-project A scaffolding only. Governance details defined in sub-project E.**

## Modes

- `--quick` — last 5 slices, `[plugin]` notes only, only if patterns clear
- `--full` — all `[plugin]` notes since last `--full`
- `--since=<date>` — explicit date range
- `--dry-run` — print proposed diffs without committing

## Aggregation steps

1. Read all `## Plugin Improvement Notes` sections from handoff docs in scope.
2. Cluster by theme - API drift / question gap / pattern win / failure mode / library version.
3. Draft edits - new `LEARNINGS.md` entries, diffs to skill prompts, new ADRs if structural.
4. Branch plugin repo (`learn/<project-slug>-<date>`), commit with source-slice citations, open PR via `gh`.
5. Post PR URL in project chat; update `STATE.yaml.learn.last_quick_pr` (or `last_full_at`).

## Safeguards

- PR-gated, never auto-merge
- Diffs must cite source slice handoffs
- CI runs fixture tests on every PR
