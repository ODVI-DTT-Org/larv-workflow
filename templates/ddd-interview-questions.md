# DDD Interview - Question Bank

This is a static reference. The `larv-domain-interview` skill reads this file and asks each section's questions one at a time, paired with a recommendation block.

## Constraints

- Business-process only. No tech stack, no library choices, no infrastructure decisions.
- Tech-leak guard: when the user mentions Laravel/Postgres/Filament etc., acknowledge and redirect:
  > "Noted - let's table that for the Discuss phase. Back to the business: ..."
- Record domain nouns and verbs verbatim in `docs/larv/ddd-interview/ubiquitous-language.md`.
- Every question paired with: `Recommendation: <option> | Why: <reason citing prior answers> | Tradeoffs: <one line>`.

## Sections (15-20 questions total)

### 1. Domain experts
- Who knows the domain best?
- Who has decision authority on ambiguities (single name preferred)?

### 2. Core purpose
- "The business exists to ___" (single sentence).
- What job does this app do for the user, independent of any tech?

### 3. Real-world processes
- Walk me through a typical day/transaction in your own words.
- Who does what, when?

### 4. Actors and roles
- List every distinct human (or system) role that interacts with the business.
- Which roles have decision-making power vs. execute-only?

### 5. Things and events
- What nouns come up repeatedly?
- What verbs come up repeatedly?
- (Agent records each verbatim - no canonicalization yet.)

### 6. Business invariants
- What rules MUST always hold? (e.g., "an invoice can never be paid twice")
- Which invariants are legally or contractually required vs. internally chosen?

### 7. Edge cases the business already knows
- Refunds / disputes / chargebacks?
- Holidays / regulatory windows / blackout periods?
- What manual workarounds happen today when the system can't handle something?

### 8. External constraints
- Regulators?
- Partners with hard SLAs?
- Audit requirements?

### 9. What's painful today
- What do people do in spreadsheets that this app should replace?
- What questions take >1 day to answer because the data is scattered?

## Outputs

After the interview, write the following files in `docs/larv/ddd-interview/`:

1. `business-purpose.md` - one paragraph + the single-sentence "the business exists to ___".
2. `domain-experts.md` - names, roles, decision authority.
3. `process-narrative.md` - the user's process description in their own words.
4. `ubiquitous-language.md` - verbatim nouns and verbs (canonicalization happens in Phase 1).
5. `business-invariants.md` - list of MUST-hold rules.
6. `edge-cases.md` - known edge cases.
7. `external-constraints.md` - regulators, partners, audit.
8. `subdomain-candidates.md` - DRAFT clustering of the above into possible subdomains; plain English; no DDD vocabulary.
