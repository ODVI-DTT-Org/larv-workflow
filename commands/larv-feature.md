---
name: larv:feature
description: Add a feature to a managed Laravel app. Mini-flow — brief, deltas, mini-premortem, slice plan, implementation loop.
---

Argument: `<feature-name>` — short slug for the feature.

Invoke the `larv-orchestrator` skill in feature mode with the provided feature name.

Requires `STATE.yaml` to exist at `docs/larv/STATE.yaml`. Reads existing docs to ground the feature in current architecture.
