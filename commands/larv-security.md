---
name: larv:security
description: Scan a repository before installing, running, adopting, or trusting it.
---

Run the non-executing repository security guard from the repo being evaluated:

```bash
bash <larv-plugin-root>/scripts/security-scan.sh "$PWD" "$PWD/docs/larv/security/manual-security-scan.md"
```

If the scan fails, stop before dependency installation or runtime execution and review `docs/larv/security/manual-security-scan.md`.
