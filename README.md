# Island

Homelab config for the Synology NAS ("Atlas"): Docker Compose stacks and DSM tasks.

## Layout

```
projects/   # Compose stacks (gateway, media, archive, …)
tasks/      # Synology/DSM scripts (e.g. free ports 80/443)
```

Each stack lives at `projects/<name>/` with a `compose.yml`. Secrets stay in git-ignored `.env` files; use the matching `.env.sample` as a template.

## Domains

- `*.tn.ojizero.dev` — Tailscale
- `*.ln.ojizero.dev` — LAN
- `*.ojizero.dev` — public (Cloudflare tunnel)

## Notes

- Pin image tags; never use `latest`
- Traefik-routed services join the external `servicenet` network
- Agent skill: `.agents/skills/upgrade-stack` bumps stack image tags
