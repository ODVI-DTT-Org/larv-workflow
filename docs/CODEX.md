# Codex CLI Compatibility

`larv` ships with both Claude Code and Codex plugin metadata.

## Local Codex Marketplace Install

From this repository root:

```bash
codex plugin marketplace add .
```

Codex reads `.agents/plugins/marketplace.json`, which points to `./plugins/larv`. In this repo that path is a symlink back to the plugin root so the repository does not duplicate itself.

## Codex Slash Command Behavior

Codex CLI 0.125.0 does not expose local marketplace `commands/*.md` files as visible slash-menu entries in the same way Claude Code does. The compatible Codex entry points are installed as a skill namespace instead:

```bash
ln -sfn <larv-plugin-root>/codex-skills ~/.agents/skills/larv
```

After restarting Codex, prompts such as `/larv:full`, `/larv:status`, and `/larv:resume` are model-visible skill triggers. They may not appear in the slash-command picker, but typing them in chat invokes the matching `larv:*` skill.

## What Codex Gets

- `.codex-plugin/plugin.json` for Codex plugin metadata
- `commands/` for the `/larv:*` command prompts
- `codex-skills/` for Codex-visible `larv:*` skill triggers
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
codex debug prompt-input 'test' | jq -r '.. | strings?' | rg 'larv:full'
```
