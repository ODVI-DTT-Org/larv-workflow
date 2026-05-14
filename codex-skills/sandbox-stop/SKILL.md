---
name: sandbox-stop
description: Use when the user types /larv:sandbox-stop or asks to stop current larv sandbox servers.
---

# larv:sandbox-stop

Run the larv sandbox stop helper for the current project:

```bash
bash /home/claude-team/kaito/workflow/scripts/sandbox.sh "$PWD" stop
```

It stops only the tmux sessions for the current larv project slug and recorded runtime ports.
