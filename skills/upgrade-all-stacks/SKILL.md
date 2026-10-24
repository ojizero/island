---
name: upgrade-all-stacks
description: Upgrade every Compose stack under projects/ in one run with a combined report.
---

# Upgrade all stacks

1. **Plan.** Every `projects/*/compose.yml` directory is a stack. Skip stacks with uncommitted changes and list them in the report.
2. **Upgrade** each stack in its own subagent, all in parallel. Tell each to leave the commit and return its report and commit message. Done when every stack has returned a report or a failure.
3. **Commit** each upgraded stack separately, one at a time, staging only `projects/<stack>/` with the message its subagent returned. Never push.
4. **Report**:
   - **Upgraded**: each stack's tables and commit.
   - **Notes for the deployer**: by stack.
   - **Unchanged**: stacks already current, skipped, or failed, with the reason.
