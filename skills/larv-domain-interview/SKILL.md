---
name: larv-domain-interview
description: Phase 0a - business-process-only DDD interview. Runs before Discuss. Outputs ubiquitous language, business invariants, edge cases, and a draft subdomain clustering, all in plain English.
---

# larv-domain-interview

Conduct a structured business-process interview before any tech-stack discussion. The output of this skill grounds every subsequent phase. Pure business: no Laravel, no Postgres, no Filament. If the user mentions tech, acknowledge and redirect.

## Trigger

Always runs in `/larv:full` greenfield mode, immediately after Phase -1 pre-flight, before Phase 0 Discuss.

## Inputs

- `docs/larv/STATE.yaml` (project metadata)
- `templates/ddd-interview-questions.md` (the canonical question bank)
- Any user-provided PRD, brief, pasted requirements, or product spec in the current conversation or repository docs

## What you do

1. Read the question bank from `templates/ddd-interview-questions.md` (relative to the plugin repo root).
2. Detect whether the user has provided a PRD or equivalent requirements document.
3. If no PRD exists, walk the user through the 9 sections. Ask one question at a time. Pair each with a recommendation block (`Recommendation / Why / Tradeoffs`).
4. If a PRD exists, use **PRD-assisted interview mode**:
   - A PRD reduces question count; it never replaces the interview.
   - First, summarize the inferred answers from the PRD under these headings: purpose, actors, business workflows, core terms, hard business rules, exceptions, external constraints, and candidate subdomains.
   - Then ask at least 5 targeted confirmation or gap questions before writing final outputs. Ask one question at a time.
   - Favor questions that validate ambiguity, workflow sequence, authority boundaries, lifecycle states, exceptions, reporting cadence, and invariants.
   - Pair each question with a recommendation block (`Recommendation / Why / Tradeoffs`) based on the PRD.
   - If the PRD is unusually complete, ask confirmation questions such as "I inferred X from the PRD. Is that correct, or should it be refined?"
   - Do not return status: complete until the user answers the targeted questions or explicitly says to accept all inferred answers as written.
5. Record nouns and verbs verbatim. Do not canonicalize yet; Phase 1 Domain handles canonicalization.
6. **Tech-leak guard:** if the user says "Laravel", "Postgres", "Filament", "Redis", or any other tech term, respond:
   > "Noted - let's table that for the Discuss phase. Back to the business: <re-ask the previous question>."
   Append the noted item silently to `docs/larv/00-discuss/library-decisions-pre-input.md`.
7. After the interview, write all 8 output files listed below to `docs/larv/ddd-interview/`.
8. Run the auto-commit:
   ```bash
   . scripts/lib/git_safe.sh
   safe_commit_docs "[larv] phase 0a: ddd interview approved"
   ```

## Required outputs

All 8 files in `docs/larv/ddd-interview/`:

- `business-purpose.md`
- `domain-experts.md`
- `process-narrative.md`
- `ubiquitous-language.md`
- `business-invariants.md`
- `edge-cases.md`
- `external-constraints.md`
- `subdomain-candidates.md`

## What you do not do

- Do not skip Phase 0a just because a PRD is detailed.
- Do not ask about libraries, frameworks, hosting, databases, or any tech.
- Do not pre-canonicalize ubiquitous-language terms. Record them verbatim.
- Do not invoke other skills.
- Do not write outside `docs/larv/ddd-interview/` and `docs/larv/00-discuss/library-decisions-pre-input.md` for tech leaks.

## Subagent return contract

```yaml
status: complete
files_written:
  - docs/larv/ddd-interview/business-purpose.md
  - docs/larv/ddd-interview/domain-experts.md
  - docs/larv/ddd-interview/process-narrative.md
  - docs/larv/ddd-interview/ubiquitous-language.md
  - docs/larv/ddd-interview/business-invariants.md
  - docs/larv/ddd-interview/edge-cases.md
  - docs/larv/ddd-interview/external-constraints.md
  - docs/larv/ddd-interview/subdomain-candidates.md
state_updates: {}
plugin_improvement_notes: (none)
```
