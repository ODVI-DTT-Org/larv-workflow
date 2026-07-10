---
name: larv-learn
description: Phase 11 - aggregate implementation reports, local learnings, and plugin improvement notes into LEARNINGS.md proposals. Supports --quick, --full, --since, and --dry-run.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-learn

Aggregate project lessons and plugin improvement signals after implementation, verification, or deployment.

## Inputs

- `docs/larv/implementation-tracker.yaml`
- `docs/larv/local-learnings.md`
- `docs/larv/09-verification/final-report.md`
- `docs/larv/10-deploy/*.md`
- `docs/larv/08-implementation/reports/IMPLEMENTATION-REPORT-*.md`
- `docs/Handsoff/slice-NN-*.md` Plugin Improvement Notes sections
- root `LEARNINGS.md`

## Modes

- `--quick`: inspect the latest five implementation reports under `docs/larv/08-implementation/reports/` and only high-confidence `[plugin]` notes.
- `--full`: inspect all reports and local learnings.
- `--since=YYYY-MM-DD`: inspect entries after a date.
- `--dry-run`: print proposed `LEARNINGS.md` additions and plugin follow-up tasks without editing files.

## What you do

1. Collect recurring failures, skipped steps, unclear handoffs, package-specific gaps, deploy friction, and verification failures.
2. Separate `[project]` lessons from `[plugin]` lessons.
3. Propose concrete plugin improvements with affected files.
4. In non-dry-run mode, append accepted plugin lessons to `LEARNINGS.md`.
5. Never modify application code.

## Output

Write or print:

- summary of project lessons
- proposed plugin improvements
- evidence file paths
- whether changes were written or dry-run only

## Subagent return contract

```yaml
status: complete
mode: "--quick|--full|--since|--dry-run"
files_written:
  - LEARNINGS.md
plugin_improvement_notes:
  - ...
```
