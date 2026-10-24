---
name: upgrade-stack
description: Upgrade a Compose stack's image tags under projects/. Use when upgrading or bumping a stack.
---

# Upgrade a stack

Move every pinned image in `projects/<stack>/compose.yml` forward to its newest release, majors and breaking changes included. An upgrade with breaking changes still goes ahead: make the changes it needs in the repo and report the steps the user must take on Atlas. **Hold** a candidate (leave its tag untouched) only when you cannot work out how to proceed with it.

Input: the stack name. Ask for it when missing.

## Rules

- Read all of `UPGRADES.md` first. Its caveats override these rules.
- Keep each image's tag style (`YYYY.MM.DD-hash`, `sha-<hash>`, linuxserver `-lsNN`, semver) and pin exact tags.
- Stay on the image's current release channel: stable stays stable, and `beta` or nightly-style tags only follow a tag already on that channel.
- Databases stay on their current major line (`postgres:18.x` stays `18.x`); a major bump needs a dump and restore.
- Skip services that use `build:`.
- `.env` files belong to the user. New variables go in `.env.sample`.

Hold a candidate when:

- its migration is ambiguous, or sources disagree on what it requires
- the changes between the current and target tags cannot be read
- the target tag fails verification

## Steps

1. **Inventory.** List each service's image and current tag.
2. **Research**, one subagent per image in parallel:
   - Find the newest tag in the same style from the registry (quay: `/api/v1/repository/<ns>/<repo>/tag/`; Docker Hub: `/v2/repositories/<ns or library>/<image>/tags/`; ghcr: registry API or GitHub releases) and cross-check upstream releases.
   - Read every release between the current and target tags for breaking changes, migrations, and renamed or removed config and environment variables.

   Done when every image has a target tag or "already latest", 1–3 highlights, the repo changes and Atlas steps it needs, or the reason to hold it.
3. **Verify** each target with `docker manifest inspect <image>:<tag>`. On failure, re-query the registry for the correct existing tag.
4. **Apply** the new tags and every repo change the upgrades need (renamed variables, changed ports, new required keys, removed settings) in the stack's files. Done when `docker compose config --quiet` passes in `projects/<stack>/`.
5. **Commit** the stack's changed files. Never push. The `Deploy:` section carries the Atlas steps to `deploy-stack`; leave it out when there are none.

   ```text
   Upgrade <service names> in <stack> stack

   - <service>: <old tag> -> <new tag> (<brief reason>)

   Deploy:
   - before: <step, e.g. down the stack and back up ./configs/jellyfin>
   - after: <step, e.g. run a full library scan>
   ```

6. **Report.**

   | Service | Old tag | New tag | Status | Changes |
   |---|---|---|---|---|

   Status is `upgraded`, `held`, or `latest`. Mark breaking changes **BREAKING**. Below the table:

   - steps the user must take on Atlas before or after `docker compose pull && docker compose up -d`, such as backups
   - each hold: why, and what would unblock it
   - caveats worth adding to `UPGRADES.md`
   - the commit hash; nothing is deployed
