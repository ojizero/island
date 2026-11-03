# Island

Docker Compose stacks for the Synology NAS "Atlas".

## Layout

- `projects/<stack>/compose.yml`: one stack per directory. Secrets live in git-ignored `.env` files, templated by `.env.sample`.
- `tasks/`: DSM scripts.
- `UPGRADES.md`: caveats for upgrading and deploying stacks.
- `skills/<name>/SKILL.md`: the agent skills. dotagents installs them per `agents.toml` into the git-ignored `.agents/` and `.claude/` as copies, so run `dotagents --project install` after editing one.

## Subagents

The skills nest subagents: a stack's subagent fans out into one per image. Use a subagent tool whose subagents can spawn their own.

## Docker lockdown

Docker APIs on Atlas are locked down as a security measure. A Docker API gives root on Atlas, so only the one container that drives it can reach it:

- Serve it as a unix socket in a volume that only its consumer mounts (forge's dind), or as a least-permission socket proxy on an `internal: true` network that only its consumer joins (gateway's `docker-proxy`).
- Keep each Docker API off every network that is not `internal: true`. Atlas's Docker 24 lets any LAN or Tailscale host with a route to a bridge reach its unpublished ports, because `FORWARD` accepts by default. The `firewall` stack drops that traffic; internal networks block it even when that stack is down.
- Treat Atlas itself as reachable from every container: each container reaches Atlas's host services (SSH, DSM, SMB) through its gateway IP, internal networks included.
- Get the user's approval before a change that opens the lockdown: a new consumer of a Docker API, a TCP listener, a socket mounted into jobs, or more privilege for a container.

## Atlas

Atlas is the SSH host `atlas` (`ssh atlas`), and the Docker context `atlas` connects through it. Atlas has no git: each stack is a plain directory at `/volume1/docker/<stack>/` holding the deployed files, the user's `.env`, and service data. Its Compose is v2.20.1. SFTP is disabled, so copy files with `scp -O`; rsync is refused.

Routers use `*.tn.ojizero.dev` hostnames (Tailscale). `*.ln.ojizero.dev` hostnames are deprecated and LAN-only: give new routers none.

Deployed state can drift from the repo, so check it there:

- `docker --context atlas compose ls`
- `docker --context atlas ps`
- `docker --context atlas inspect <container>`

Use `atlas` to read state. Edit the repo and let the user deploy; change Atlas only when the user asks for that specific change.
