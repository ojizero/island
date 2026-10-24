---
name: deploy-stack
description: Deploy a Compose stack from projects/ to Atlas, including the steps its upgrades need. Use when deploying or rolling out a stack.
---

# Deploy a stack

Bring a stack on Atlas in line with the repo. A deploy carries the steps its changes need, such as backing up state before a one-way migration. You collect those steps, agree a plan with the user, then run it.

Input: the stack name. Ask for it when missing.

## Rules

- Read all of `UPGRADES.md` first. Its caveats override these rules.
- Run Compose from the stack's directory on Atlas. From the local checkout, relative bind mounts would resolve to local paths.
- Container Manager owns the project names, and some differ from the directory (`adguard` runs as `adguard-home`). Always pass `-p <project>`.
- SFTP is disabled, so copy with `scp -O`.
- `.env` files and service data belong to the user. Read `.env` variable names only, never values.

## Steps

1. **Resolve** the project name and directory from the `CONFIG FILES` column of `docker --context atlas compose ls`. A stack missing there has never been deployed; confirm with the user before a first deploy.
2. **Diff** the repo against Atlas. The deployable files are the stack's tracked files minus `.gitignore`, `*.sample`, and `*.md`. Fetch each Atlas copy and keep it, since it is the rollback. Done when you know every changed file and every image moving from its deployed tag to its repo tag.
3. **Collect steps** for every change:
   - `Deploy:` sections in the stack's upgrade commits (`git log -- projects/<stack>/`) whose tags fall between the deployed and repo tags.
   - For image changes without them, the release notes between the deployed and repo tags.
   - Caveats in `UPGRADES.md` that apply to this stack.
   - Host-only state the repo cannot see: variables in `.env.sample` missing from `.env`, removed or renamed keys in git-ignored config files on Atlas, and new bind-mount directories that must exist with the right owner.

   Done when every changed image and file has its steps, or "none".
4. **Plan** in three parts, marking who does each step (you over SSH, or the user in an app or with `sudo`):
   - **Before**: backups and other pre-steps, following the breaking-change notes in `UPGRADES.md`.
   - **Deploy**: copy the changed files, run `docker compose config --quiet` on Atlas (its Compose may be older than yours), then `pull` and `up -d`.
   - **After**: in-app steps, such as rescans, settings, and connection tests.

   Present the plan and wait for the user's go-ahead.
5. **Run** the plan. Hand user steps over and wait for them to confirm each one. Follow each changed container's first start with `docker --context atlas logs -f <container>`, and let migrations finish without restarting. If validation or startup fails, stop and propose a rollback from the saved files and backups. Done when every container is running, healthy where it has a healthcheck, and its logs are free of errors.
6. **Report**: what was deployed, backups made and when they are safe to delete, the remaining after steps, and caveats worth adding to `UPGRADES.md`.
