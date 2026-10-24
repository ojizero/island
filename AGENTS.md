# Island

Docker Compose stacks for the Synology NAS "Atlas".

## Layout

- `projects/<stack>/compose.yml`: one stack per directory. Secrets live in git-ignored `.env` files, templated by `.env.sample`.
- `tasks/`: DSM scripts.
- `UPGRADES.md`: caveats for upgrading and deploying stacks.

## Subagents

The skills nest subagents: a stack's subagent fans out into one per image. Use a subagent tool whose subagents can spawn their own.

## Atlas

Atlas is the SSH host `atlas` (`ssh atlas`), and the Docker context `atlas` connects through it. Atlas has no git: each stack is a plain directory at `/volume1/docker/<stack>/` holding the deployed files, the user's `.env`, and service data. Its Compose is v2.20.1. SFTP is disabled, so copy files with `scp -O`; rsync is refused.

Deployed state can drift from the repo, so check it there:

- `docker --context atlas compose ls`
- `docker --context atlas ps`
- `docker --context atlas inspect <container>`

Use `atlas` to read state. Edit the repo and let the user deploy; change Atlas only when the user asks for that specific change.
