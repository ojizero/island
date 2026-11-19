# Operations

Rules and catches for running, deploying, and upgrading stacks: general notes first, then one `## <stack>` section each.

## Breaking changes

Be bold: take the upgrade, breaking or not, and make it safe to undo.

- **Back up** when a change to state cannot be undone, such as a one-way migration. With the stack down, copy the data directory wholesale to `<path>.bak.<old version>`.
- **Monitor** the first start through the logs. Let migrations finish without restarting, then check the service works.
- **Revert** when it goes wrong: restore the previous files, copy the backup directory back over the data, and redeploy the old tag.
- **Dependency majors**: when other services depend on a service, take its major only if every dependent supports the new version; otherwise skip it. For example, Postgres stays on its current major until every app using it supports the next one.

## Deploys

- Atlas's Docker does not create a missing bind-mount source; `up` fails with `Bind mount failed: '<path>' does not exist`. On a first deploy, create every bind-mount directory first, with the owner the container needs.
- Keep each `.env` on Atlas readable only by its owner. The ACL that `/volume1/docker/` passes down gives `everyone` read access. After you create or replace a `.env`, run `/usr/syno/bin/synoacltool -del .env` (skip it when `ls -l` shows no `+`), then `chmod 600 .env`. Compose and Container Manager can still read it. To undo, run `synoacltool -enforce-inherit .env`. If someone applies the parent's permissions to its children in DSM, run the two commands again.

## adguard

- Runs on Atlas under the Compose project name `adguard-home`.
- AdGuard is Atlas's DNS server. While it restarts, Atlas cannot resolve names, and pulls for other stacks fail. When you deploy many stacks, deploy adguard last, or pull the images for the other stacks first.

## archive

- `getmeili/meilisearch`: pin to the version that Karakeep's own compose uses for the target Karakeep release. `MEILI_UPGRADE_DB` migrates `data.ms` on start, one-way ([Karakeep guide](https://github.com/karakeep-app/karakeep/blob/v0.35.0/docs/docs/06-administration/10-meilisearch-upgrade.md)).

## cloudflare

- Runs on Atlas under the Compose project name `cloudflare-tunnel`.

## dashboard

- Runs on Atlas under the Compose project name `dashboards`.

## firewall

- After a DSM or Container Manager update, check that the rule still applies: from a LAN host with a route to `172.16.0.0/12` via Atlas, a port that a container listens on must time out. Container IPs and ports change, so pick the target when you run the check: a container's IP from `docker --context atlas network inspect servicenet`, and a port it listens on from its `expose` in the repo. As a control, Atlas's SSH (port 22) on the network's gateway IP must connect; this shows that the route goes through Atlas. Synology wires `FORWARD` → `DEFAULT_FORWARD` → `DOCKER-USER`; if an update changes that, the rule can stop applying without an error.

## forge

- Atlas's kernel has no overlayfs and no iptables raw table, so dind needs `--storage-driver=btrfs` and `DOCKER_INSECURE_NO_IPTABLES_RAW=1`. Keep both on a dind upgrade.
- Job containers resolve only dotted names through dind's DNS, so the runner address and `cache.host` use `<container>.<network>`.
- The stack runs on Atlas and on sagittarius-a: deploy a change to both. Atlas's Compose 2.20 recreates a service when its `profiles` change.

## media

- Jellyfin needs more inotify watches than DSM's limit of 8192. `tasks/raise_inotify_watches.sh` raises it to 131072. Add it in DSM Task Scheduler as a boot-up triggered task with user `root`, run it once, then restart `jellyfin`. Check: `docker --context atlas logs --since <start> jellyfin 2>&1 | grep -c "inotify watches"` prints `0`.

## treasury

- `postgres`: stay on major 17 until the Sure image ships newer PostgreSQL client tools. Its `pg_dump` cannot read a newer server ([Sure Docker docs](https://github.com/we-promise/sure/blob/v0.7.6/docs/hosting/docker.md), "Backups, upgrades and rollbacks").
- `ghcr.io/we-promise/sure`: pin a release such as `0.7.6`, not `stable`. Tags have no `v` prefix. Skip the `-alpha` pre-releases. Sure migrates the database on start, so back up `sure/postgres` first.
- Never change `SECRET_KEY_BASE` or the `ACTIVE_RECORD_ENCRYPTION_*` keys in `.env`. Sure 0.7.6 cannot rotate the keys, and data encrypted with old keys cannot be read. A database backup is useful only with the keys and `SECRET_KEY_BASE` that were set when it was taken.
- To turn on encryption for data written without the keys: set the keys and `ACTIVE_RECORD_ENCRYPTION_SUPPORT_UNENCRYPTED_DATA=true`, recreate `sure-web` and `sure-worker`, run `bin/rails security:backfill_encryption` with `DRY_RUN=false` in `sure-web`, then remove the flag and recreate them again. Without the backfill, login fails: Sure cannot find a user by a plaintext email. The task does not cover `ApiKey` or `IbkrItem` rows.
- The first start builds the database, about 150 tables, and takes about 7 minutes on Atlas. Do not restart it. Until it finishes, `sure-web` logs nothing and `sure-worker` logs `relation ... does not exist` errors. When `/up` returns 200, restart `sure-worker` once.
