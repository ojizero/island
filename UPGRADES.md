# Upgrade caveats

Catches learned from past upgrades and deploys: general notes first, then one `## <stack>` section each.

## Breaking changes

Be bold: take the upgrade, breaking or not, and make it safe to undo.

- **Back up** when a change to state cannot be undone, such as a one-way migration. With the stack down, copy the data directory to `<path>.bak.<old version>`.
- **Monitor** the first start through the logs. Let migrations finish without restarting, then check the service works.
- **Revert** when it goes wrong: restore the previous files and the backup, and redeploy the old tag.
- **Postgres majors** cannot reuse the old data directory. The deploy needs a `pg_dumpall` before and a restore into the new major after.

## adguard

- Runs on Atlas under the Compose project name `adguard-home`.

## archive

- `getmeili/meilisearch`: pin to the version Karakeep recommends for the target Karakeep release. A Meilisearch bump can need a data migration (wiping `data.ms` and a full reindex). See the [Karakeep Meilisearch upgrade guide](https://docs.karakeep.app/administration/troubleshooting#upgrading-meilisearch---migrating-the-meilisearch-db-version).

## cloudflare

- Runs on Atlas under the Compose project name `cloudflare-tunnel`.

## dashboard

- Runs on Atlas under the Compose project name `dashboards`.
