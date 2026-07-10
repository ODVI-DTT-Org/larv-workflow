# DOX / larv Risk Reduction Report

Date: 2026-07-01
Pilot: `/home/claude-team/kaito/dtt-dashboard`
Scope: larv generator/templates and generated contract docs only. No DTT application behavior changes were made for this report.

## Measured Results

| Risk | Before | After |
|---|---:|---:|
| Root starting-point length | 150 lines each for `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`; 52 lines for Cursor | 56 lines each for root/Claude/Gemini/Codex; 54 lines for Cursor |
| Raw contract placeholders | 4 raw `_(... TBD)_` placeholders in `docs/Handsoff.md` | 0 raw `TBD` contract placeholders found |
| Runtime host leakage | Runtime URL and STATE pointed at `46.250.229.188:25000`; root files were stale long-form contracts | Contract checker confirms `docs/Handsoff.md`, root files, Cursor rule, STATE, and `sandbox-url.txt` agree |
| Model-specific Opus/Sonnet/Haiku wording | Not found in measured files | 0 found |
| Unresolved `{{token}}` output | Not found in measured files | 0 found |
| Stale nested generated contracts | `app/AGENTS.md`, `resources/AGENTS.md`, `tests/AGENTS.md`, `docs/larv/AGENTS.md`, and `docs/Handsoff/AGENTS.md` existed from the prior pilot | Removed; generator no longer emits nested contracts in this stage |
| Automated contract gate | None | `scripts/check-dox-contracts.sh /home/claude-team/kaito/dtt-dashboard` passed |

## Pros

- Root files are now routing contracts instead of duplicated handoff manuals.
- Missing source docs render explicit absence notices and tell agents not to invent architecture or product facts.
- Runtime host agreement is machine-checked across Handsoff, root contracts, Cursor, STATE, and sandbox URL.
- Intentional examples such as `sandbox.example.com:<port>` remain allowed in templates/tests, while real generated projects fail if stale placeholder hosts leak when runtime URL data exists.
- Dirty-worktree and generated-file regeneration guidance is explicit in generated contracts.

## Cons

- Agents must follow links into `docs/Handsoff.md` and slice docs for detailed workflow instructions; root files intentionally carry less detail.
- The checker is conservative: contract files with raw `TBD`, unresolved tokens, or model-specific Opus/Sonnet/Haiku guidance fail even if a human intended them as notes.
- This stage removes generated nested `AGENTS.md` files, so path-local discovery relies on root routing until a later pilot proves nested contracts are worth the upkeep.

## Remaining Risks

- DTT still has unrelated dirty application/test/docs changes; this report only validates the generated contract layer.
- The checker validates consistency and obvious stale content, not whether every referenced product document is semantically current.
- Fresh-agent implementation trials are still needed to measure whether shorter root contracts reduce over-reading without losing necessary context.

## Recommendation

Go for one real DTT feature trial using the reduced DOX contract tree. Use `scripts/check-dox-contracts.sh /home/claude-team/kaito/dtt-dashboard` as a required pre-flight and completion gate. Do not add nested `AGENTS.md` files unless the trial shows agents repeatedly miss local context that root routing and slice/feature docs already name.
