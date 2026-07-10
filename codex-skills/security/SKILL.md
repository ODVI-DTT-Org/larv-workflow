---
name: security
description: Use when the user types /larv:security or asks to scan an existing repository, Laravel app, package, dependency, or tool before installing, running, adopting, or using it.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv:security

Run a static, non-executing repository guard before trusting a repo, package, or tool. This skill is for "scan before use" checks, not incident response or full malware reverse engineering.

## Core Rule

Do not install dependencies, source scripts, run package lifecycle scripts, execute project binaries, or run unknown repository commands before the scan passes.

## Quick Scan

From the repository being evaluated:

```bash
bash <larv-plugin-root>/scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/manual-security-scan.md"
```

For a repo outside the current directory:

```bash
bash <larv-plugin-root>/scripts/security-scan.sh "/path/to/repo" "/path/to/repo/docs/larv/security/manual-security-scan.md"
```

## What The Guard Checks

- Static malware indicators: download-and-execute shell pipelines, base64 decode-to-shell, PHP `eval(base64_decode(...))`, request-controlled PHP/Node command execution, PowerShell encoded commands, reverse shells, cron/systemd persistence, hardcoded private keys, and common cloud/token secrets.
- Git execution hooks: custom `core.hooksPath` and active non-sample hooks under `.git/hooks`.
- Package install hooks: npm lifecycle scripts and Composer script hooks that can execute during install/update/autoload.
- Dependency advisories: `composer audit`, `npm audit`, `pnpm audit`, and Yarn audit when matching lockfiles and tools are present.

## Result Handling

- `Status: passed`: continue normal work, while still reviewing unusual package hooks before installation.
- `Status: failed`: stop. Read the report, identify the exact files and rules, and ask the user whether to remove, patch, replace, or reject the repo/package.
- `Status: bypassed`: only acceptable when the user explicitly acknowledges the report and requests a controlled false-positive bypass with `LARV_SECURITY_ALLOW_FAIL=1`.

## Investigation Constraints

When a finding appears, inspect files with read-only commands such as `rg`, `sed`, `git show`, and package metadata commands that do not execute project scripts. Do not "try running it" to see what happens.

## Laravel Workflow Integration

For larv-managed Laravel work, use this same scanner:

- Before greenfield planning through `/larv:full`, `pre-flight.sh` writes `docs/larv/security/pre-flight-security.md`.
- Before Phase 8 implementation, write `docs/larv/security/pre-implementation-security.md`.
- Before and after each implementation slice, write reports under `docs/larv/security/slices/`.
