# ADR 0001 - Bundled Marketplace As The Distribution Model

Date: 2026-05-04
Status: Accepted
Decision-makers: maintainers@example.org

## Context

`larv` orchestrates three upstream sources: `masterplan`, `superpowers-laravel`, and `domain-driven-design`. The plugin must be installable in one step, reproducible across machines, and resilient to upstream changes.

## Decision

Adopt a bundled marketplace model. `larv` vendors pinned versions of all four sources inside `bundle/` and ships as one Claude Code plugin.

## Rationale

- One install path for team members.
- Pinned versions make environments reproducible.
- Upstream breaking changes only enter through reviewed bundle updates.
- `larv` wraps upstream behavior; it does not fork and patch it.

## Consequences

Renovate opens dependency PRs, CI runs fixture tests, and repo size grows modestly. This tradeoff is acceptable for a private team plugin.

## Canonical Upstream Sources

- `masterplan`
- `superpowers-laravel`
- `domain-driven-design`
- local Attio-style galleries
