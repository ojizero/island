# Upgrade caveats

Catches learned from past upgrades and deploys: general notes first, then one `## <stack>` section each.

## Breaking changes

Be bold: take the upgrade, breaking or not, and make it safe to undo.

- **Back up** when a change to state cannot be undone, such as a one-way migration. With the stack down, copy the data directory wholesale to `<path>.bak.<old version>`.
- **Monitor** the first start through the logs. Let migrations finish without restarting, then check the service works.
- **Revert** when it goes wrong: restore the previous files, copy the backup directory back over the data, and redeploy the old tag.
- **Dependency majors**: when other services depend on a service, take its major only if every dependent supports the new version; otherwise skip it. For example, Postgres stays on its current major until every app using it supports the next one.

## adguard

- Runs on Atlas under the Compose project name `adguard-home`.
- AdGuard is Atlas's DNS server. While it restarts, Atlas cannot resolve names, and pulls for other stacks fail. When you deploy many stacks, deploy adguard last, or pull the images for the other stacks first.

## archive

- `getmeili/meilisearch`: pin to the version Karakeep recommends for the target Karakeep release. A Meilisearch bump can need a data migration (wiping `data.ms` and a full reindex). See the [Karakeep Meilisearch upgrade guide](https://docs.karakeep.app/administration/troubleshooting#upgrading-meilisearch---migrating-the-meilisearch-db-version).

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

## treasury

- `postgres`: stay on major 17 until the Sure image ships newer PostgreSQL client tools. Its `pg_dump` cannot read a newer server ([Sure Docker docs](https://github.com/we-promise/sure/blob/v0.7.6/docs/hosting/docker.md), "Backups, upgrades and rollbacks").
- `ghcr.io/we-promise/sure`: pin a release such as `0.7.6`, not `stable`. Tags have no `v` prefix. Skip the `-alpha` pre-releases. Sure migrates the database on start, so back up `sure/postgres` first.
- Never change `SECRET_KEY_BASE` in `.env`: Sure derives its encryption keys from it.
