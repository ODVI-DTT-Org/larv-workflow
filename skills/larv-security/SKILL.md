---
name: larv-security
description: Repository security guard for Laravel and larv workflows before adopting, installing, running, implementing, or trusting app code and packages.
---

## larv Headroom Combo

Before context-heavy work, run `bash <larv-plugin-root>/scripts/headroom-combo.sh status "$PWD"` to activate Ponytail + gated Headroom + Caveman. If Headroom falls back, continue normally.

# larv-security

Use this as the larv workflow's reusable repository guard. It wraps `scripts/security-scan.sh` and enforces a static-first policy before any Laravel app bootstrap, Composer install/update, npm install/build, package adoption, or implementation slice.

## Required Command

```bash
bash <larv-plugin-root>/scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/manual-security-scan.md"
```

Use a more specific report path when the scan is part of a phase:

- `docs/larv/security/pre-flight-security.md`
- `docs/larv/security/pre-implementation-security.md`
- `docs/larv/security/slices/pre-slice-NN.md`
- `docs/larv/security/slices/post-slice-NN.md`

## Hard Gates

- A failed scan blocks planning, adoption, dependency installation, app bootstrap, implementation, and verification until the user chooses a remediation.
- A bypass must be explicit: the user acknowledges the report path and requests `LARV_SECURITY_ALLOW_FAIL=1`. Record bypassed as `bypassed`, never `passed`.
- Investigation must be read-only. Do not execute repository code, package scripts, unknown binaries, or dependency lifecycle hooks to diagnose the finding.

## Coverage

The scanner checks common embedded-malware and supply-chain indicators:

- Shell download-and-execute chains such as `curl ... | bash`.
- Obfuscated shell execution such as `base64 -d | sh`.
- PHP webshell-style execution: `eval(base64_decode(...))`, `assert($_REQUEST...)`, and request-controlled `system`, `exec`, `shell_exec`, or `passthru`.
- Node request-controlled process execution through `exec`, `execSync`, `spawn`, or `spawnSync`.
- PowerShell encoded commands, reverse shells, cron/systemd persistence, hardcoded private keys, and common cloud/token secrets.
- Git hooks and custom hook paths.
- npm and Composer lifecycle scripts that can execute during install/update/autoload.
- Lockfile dependency advisories through Composer, npm, pnpm, and Yarn audit commands when those tools are available.
