---
name: upgrade-all-stacks
description: Upgrade every Compose stack under projects/ in one run with a combined report.
---

# Upgrade all stacks

1. **Plan.** Every `projects/*/compose.yml` directory is a stack. Skip stacks with uncommitted changes and list them in the report.
2. **Upgrade** each stack in its own subagent, all in parallel. Each subagent leaves its changes uncommitted and returns its report and commit message. Done when every stack has returned a report or a failure.
3. **Commit** each upgraded stack separately, one at a time, staging only `projects/<stack>/` with the message its subagent returned. Never push.
4. **Report**, Atlas steps first because they need the user:
   - **Atlas steps**: every step the user must take before deploying, by stack.
   - **Upgraded**: one row per stack with stack, commit, and services upgraded.
   - **Held**: each hold with its stack and what would unblock it.
   - **Unchanged**: stacks already current, skipped, or failed, with the reason.
   - **Caveats**: proposed additions to `UPGRADES.md`.
