---
name: deploy-stack
description: Deploy a Compose stack from projects/ to Atlas, including the steps its upgrades need. Use when deploying a stack.
---

# Deploy a stack

Bring a stack on Atlas in line with the repo. A deploy carries the steps its changes need, such as backing up state before a one-way migration. You collect those steps into a plan, then run it.

Input: the stack name. Ask for it when missing.

## Rules

- Read all of `UPGRADES.md` first.
- Run Compose from the stack's directory on Atlas. From the local checkout, relative bind mounts would resolve to local paths.
- Always pass `-p <project>`.
- `.env` files and service data belong to the user. Read `.env` variable names only, never values.

## Steps

1. **Resolve** the project name and directory from the `CONFIG FILES` column of `docker --context atlas compose ls`. A stack missing there has never been deployed.
2. **Diff** the repo against Atlas. The deployable files are the stack's tracked files minus `.gitignore`, `*.sample`, and `*.md`. Fetch each Atlas copy into `/tmp/atlas-<stack>-<date>/` and keep it, since it is the rollback. Done when you know every changed file and every image moving from its deployed tag to its repo tag.
3. **Work out the steps** for every change by reasoning over its traces:
   - The stack's commits back to the one whose `compose.yml` matches the Atlas copy (`git log -p -- projects/<stack>/compose.yml`): their changelog lines name what changed and what may break.
   - Caveats in `UPGRADES.md` that apply to this stack.
   - The release notes between the deployed and repo tags, when the traces leave a change unclear.
   - Host-only state the repo cannot see: variables in `.env.sample` missing from `.env`, removed or renamed keys in git-ignored config files on Atlas, and new bind-mount directories that must exist with the right owner.

   When you cannot settle what a change needs, **escalate**: hand it and your findings to a subagent on the strongest model available, unless that is already you. Done when every changed image and file has its steps, or "none".
4. **Plan** in three parts, marking who does each step (you over SSH, or the user in an app or with `sudo`):
   - **Before**: `down` the stack, then the backups and other pre-steps the changes call for. Back up (whole data directories, copied) only a change a trace documents as one-way, such as a migration the old version cannot run against. An additive migration or a plain release needs none.
   - **Deploy**: copy the changed files, run `docker compose config --quiet` on Atlas, then `pull` and `up -d`.
   - **After**: in-app steps, such as rescans, settings, and connection tests.

   Present the plan, then run it. Wait for the user's go-ahead only on an extreme case: a step no backup or saved file can undo, such as wiping data; a change escalation could not settle; or a first deploy.
5. **Run** the plan. Hand user steps over and wait for them to confirm each one. Follow each changed container's first start with `docker --context atlas logs -f <container>`, and let migrations finish without restarting. If validation or startup fails, stop and propose a rollback from the saved files and backups. Done when every container is running, healthy where it has a healthcheck, and its logs show no errors after any migration finished.
6. **Report**: what was deployed, backups made and when they are safe to delete, the remaining after steps, and caveats worth adding to `UPGRADES.md`.
