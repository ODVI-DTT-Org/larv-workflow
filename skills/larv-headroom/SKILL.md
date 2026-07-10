---
name: larv-headroom
description: Use at the start of every larv skill, command wrapper, and workflow phase to activate the Ponytail + gated Headroom + Caveman combo; checks Headroom through scripts/headroom-combo.sh, applies YAGNI/Ponytail discipline, preserves Caveman style, and falls back without Headroom when unsafe or unavailable.
---

# larv Headroom Combo

Before context-heavy larv work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"`. Continue normally if Headroom falls back.

Ponytail is active: keep the smallest correct scope, reuse existing project patterns, and avoid new abstractions or packages unless the current task requires them.

Headroom is allowed only through `scripts/headroom-combo.sh status` and `scripts/token-optimizer.sh`. Safe mode is direct compression with workspace-bounded state under `docs/larv/headroom`. Do not use proxy, wrap, learning, memory, Docker wrapper, global agent config mutation, shell hooks, autostart files, npm postinstall flows, or `curl | sh`.

Caveman is strict `full` by default for allowlisted larv flows. Caveman style comes from the existing larv state and `scripts/caveman.sh`; if the dependency is unavailable, report `full-unavailable` instead of silently using normal style.

To measure optimizer savings on a file or stdin, use:

```bash
bash <larv-plugin-root>/scripts/token-optimizer.sh measure "$PWD" <file|->
```

Report `tokens_before`, `tokens_after`, `tokens_saved`, `savings_percent`, and `compression_ratio`.

Measurement first tries gated Headroom direct compression. If Headroom protects code or does not meet the 50% savings target, the script applies `larv-context-pack`, a local lossy outline for planning, status, and progress reports. When `exact_replay=false`, re-read the original file before patching exact bytes.
