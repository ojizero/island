# Upgrade caveats

Catches learned from past upgrades and deploys: general notes first, then one `## <stack>` section each. Read all of it before upgrading or deploying, and add to it when either turns up something that will matter next time.

## Breaking changes

Be bold: take the upgrade, breaking or not, and make it safe to undo.

- **Back up** when the breaking-change analysis finds a change to state that cannot be undone, such as a one-way migration. That analysis decides what to back up and may need a larger model. A backup means `down` the stack, then copy the data directory to `<path>.bak.<old version>`.
- **Monitor** the first start through the logs. Let migrations finish without restarting, then check the service works.
- **Revert** when it goes wrong: restore the previous files and the backup, and redeploy the old tag.

## adguard

- Runs on Atlas under the Compose project name `adguard-home`, not `adguard`.

## archive

- `getmeili/meilisearch`: pin to the version Karakeep recommends for the target Karakeep release. A Meilisearch bump can need a data migration (wiping `data.ms` and a full reindex). See the [Karakeep Meilisearch upgrade guide](https://docs.karakeep.app/administration/troubleshooting#upgrading-meilisearch---migrating-the-meilisearch-db-version).
