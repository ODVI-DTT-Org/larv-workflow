# LEARNINGS

This file is the larv plugin's compounding self-knowledge. It is loaded by every `/larv:full` run during pre-flight so each project benefits from prior projects.

## How Entries Get Here

Slice and phase handoffs include a `## Plugin Improvement Notes` section. Notes prefixed `[plugin]` are generalizable; `[project]` notes remain project-specific. `/larv:learn` aggregates `[plugin]` notes and opens a PR with proposed edits.

## Sections

Entries are indexed by topic, not chronology. Add to the matching section.

## Library version notes

<!-- API drift, version-specific gotchas, and supported versions. -->

- [plugin] 2026-05-08: For fresh Laravel 13 apps, treat the compatible starter matrix as Filament 4, Pest 4, and Larastan 3. Filament 3 stops at Laravel 12, and Pest 3 expects PHPUnit 11 while Laravel 13 ships PHPUnit 12. Source: anonymized implementation learning report.

- [plugin] 2026-05-08: Laravel 13's default Tailwind v4 scaffold is `@theme`-driven. When Filament theming is needed, prefer `php artisan make:filament-theme <panel>` and keep the generated Vite-aware stubs rather than reintroducing `tailwind.config.js`-style `@config` wiring. Source: anonymized implementation learning report.

## Discuss-phase questions

<!-- Questions to add to Phase 0 based on missing-information incidents. -->

## Patterns promoted

<!-- Non-obvious approaches that worked cleanly and should become defaults. -->

- [plugin] 2026-05-21: For apps that depend on AI/LLM/STT, model each capability as a Domain **port** with a real adapter AND a **deterministic fake**, switched by one env var (e.g. `INTERVIEW_AI_DRIVER=fake|llm`). The fake makes the whole app demoable in the sandbox with zero external keys, makes tests reproducible, and keeps the integrity invariants (e.g. evidence must be verbatim) in the Domain rather than the adapter. Pair with a production guard that forbids the fake driver (and any dev-auth bypass) when `app()->environment('production')`. Source: anonymized AI workflow app learning report.

## Failure modes prevented

<!-- Recurring failure modes and the guards added for them. -->

- [plugin] 2026-05-08: Greenfield sandbox bootstrap must not assume `artisan` already exists. Slice 01 should scaffold Laravel before rerunning bootstrap, and generated runtime docs should make that ordering explicit. Source: anonymized sandbox bootstrap learning report.

- [plugin] 2026-05-08: Sandbox runtime scripts should derive `APP_ROOT` from `docs/larv/07-runtime/` as three levels up, allow an explicit `APP_ROOT` override, and bind `php artisan serve` to `0.0.0.0` for external VM access. The two-level path and `127.0.0.1` default both produced broken sandboxes. Source: anonymized implementation learning report.

- [plugin] 2026-05-08: Sandbox defaults should tolerate Redis-backed Laravel configs even when the VM lacks the PHP Redis extension. Prefer a documented `predis` fallback over assuming `ext-redis` is present. Source: anonymized sandbox dependency learning report.

- [plugin] 2026-05-21: The handsoff renderer (`scripts/lib/handsoff.sh :: __handsoff_render_template`) substitutes tokens with bash `out="${out//\{\{key\}\}/$value}"`. Bash treats a literal `&` in the replacement string as "the matched text", so every `&` inside an inlined doc (ADR aggregator, C4, slice plan) is rewritten to `{{<that_token>}}` in `docs/Handsoff.md`. Repro: `t="x {{k}} y"; v="a & b"; echo "${t//\{\{k\}\}/$v}"` → `x a {{k}} b y`. Fix: sanitize `&`→`\&`... (no help in bash `${//}`); use `awk`/`perl -pe` substitution instead, or `printf`-based replace. Source: anonymized implementation learning report.

- [plugin] 2026-05-21: `hooks/guard-pre-tool.sh` refuses Write/Edit to any path matching `*token*`, but `larv-plan` mandates `docs/larv/06-implementation/token-budget.md` — so the Write tool is blocked on a required planning file (workaround: create it via Bash heredoc). Narrow the secret glob (`*api*token*`, `*access*token*`, `*.token`, `*refresh*token*`) or whitelist `docs/larv/**`. Source: anonymized implementation learning report.

## Composition lessons

<!-- How upstream skills interact in practice. -->

## Maintenance

When this file approaches 500 lines, `/larv:learn` should propose a split into per-section files under `learnings/`.

## 2026-05-06 — Discipline rules from MVP design

[plugin] Three invariants hold all design choices together:

1. **Venue parity**: same-session, subagents, and foreign-AI all read the same handsoff. No special internal-only Phase 8 logic.
2. **Handsoff self-containment**: every action a foreign AI takes is inline bash inside the handsoff document. No `scripts/lib/*` references.
3. **Probe-before-announce**: no URL is printed until both inside-VM and outside curl confirm the service responds.

Bake these into every future skill prompt; they're easy to forget and load-bearing.

[project] When asking the user a question, always pair it with `Recommendation / Why / Tradeoffs`. Strong norm, not enforced — easy for skills to drift.

## 2026-05-06 - Article-driven mapping vs frozen baked-in mapping

[plugin] When a skill's behavior depends on a third-party reference (Phase 1's Laravel-DDD mapping cites a medium article), prefer WebFetch at skill runtime over baking the article's specifics into the spec. The article evolves; our spec freezes the moment it's pasted in. Runtime fetch keeps the mapping current at the cost of needing internet during Phase 1.

[plugin] When two phases need a static server (Phase 3 mockups, Phase 6.5 doc-site), share a lib (`static_server.sh`). Don't duplicate the start/probe/stop sequence per skill.
