---
name: upgrade-stack
description: Upgrade a Compose stack's image tags under projects/. Use when upgrading or bumping a stack.
---

# Upgrade a stack

Move every pinned image in `projects/<stack>/compose.yml` forward to its newest release, majors and breaking changes included. An upgrade with breaking changes still goes ahead: make the changes it needs in the repo.

Input: the stack name. Ask for it when missing.

## Rules

- Read all of `UPGRADES.md` first.
- Keep each image's tag style (`YYYY.MM.DD-hash`, `sha-<hash>`, linuxserver `-lsNN`, semver) and pin exact tags.
- Stay on the image's current release channel: stable stays stable, and `beta` or nightly-style tags only follow a tag already on that channel.
- `.env` files belong to the user. New variables go in `.env.sample`.

## Escalate

When you cannot settle how to proceed with a candidate (its migration is ambiguous, sources disagree, or the changes between the tags cannot be read), **escalate**: hand the candidate and your findings to a subagent on the strongest model available, unless that is already you.

**Hold** a candidate (leave its tag untouched) only when escalation cannot settle it either, or when the target tag fails verification even after re-querying the registry.

## Steps

1. **Inventory.** List each service's image and current tag.
2. **Research**, one subagent per image in parallel:
   - Find the newest tag in the same style from the registry (quay: `/api/v1/repository/<ns>/<repo>/tag/`; Docker Hub: `/v2/repositories/<ns or library>/<image>/tags/`; ghcr: registry API or GitHub releases) and cross-check upstream releases.
   - Read every release between the current and target tags for breaking changes, migrations, and renamed or removed config and environment variables.

   Done when every image has a target tag or "already latest", its changes, what may break, and the repo changes it needs, or the reason to hold it.
3. **Verify** each target with `docker manifest inspect <image>:<tag>`. On failure, re-query the registry for the correct existing tag.
4. **Apply** the new tags and every repo change the upgrades need (renamed variables, changed ports, new required keys, removed settings) in the stack's files. Done when `docker compose config --quiet --no-interpolate` passes in `projects/<stack>/`.
5. **Commit** only this stack: `git add projects/<stack>/` then `git commit -m "<message>" -- projects/<stack>/`. Never push. When told to leave the commit, return the message instead.

   ```text
   Upgrade <service names> in <stack> stack

   - <service>: <old tag> -> <new tag> (<what changed; what may break>)
   ```

6. **Report.**

   | Service | Old | New | Changes | May break |
   |---|---|---|---|---|

   A held service keeps its old tag under New, with the reason under Changes. Below the table, the major notes for the deployer to consider, such as a one-way migration.
