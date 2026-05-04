# Codex CLI Compatibility

`larv` ships with both Claude Code and Codex plugin metadata.

## Local Codex Marketplace Install

From this repository root:

```bash
codex plugin marketplace add .
```

Codex reads `.agents/plugins/marketplace.json`, which points to `./plugins/larv`. In this repo that path is a symlink back to the plugin root so the repository does not duplicate itself.

## What Codex Gets

- `.codex-plugin/plugin.json` for Codex plugin metadata
- `commands/` for the `/larv:*` command prompts
- `skills/` for the larv routing skills
- `scripts/` for executable runtime helpers
- `bundle/` for vendored upstream dependencies

## Runtime Helpers

Codex can run the same shell helpers used by Claude Code:

```bash
bash scripts/pre-flight.sh <project-dir> <project-name> greenfield
bash scripts/status.sh <project-dir>
bash scripts/resume.sh <project-dir>
```

## Verification

```bash
bats tests/codex.bats
bats tests/
```
