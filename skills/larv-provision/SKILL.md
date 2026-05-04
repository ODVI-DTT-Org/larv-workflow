---
name: larv-provision
description: Phase 7 wrapper - sandbox VM provisioning. Sub-project C defines the runtime mechanics.
---

# larv-provision

> **STUB — sub-project A scaffolding only. The full prompt for this skill is defined in sub-project B; sandbox runtime mechanics defined in sub-project C.**

## Phase responsibility

SSH to VM, deploy Docker compose stack, configure firewall + reverse proxy + TLS, seed DB, smoke-test.

## Upstream skills invoked

- (none — larv-owned, depends on sub-project C scripts)

## Required outputs

- `docs/larv/07-runtime/sandbox-runbook.md`

## Subagent return contract

See spec §8.
