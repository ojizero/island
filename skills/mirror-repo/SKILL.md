---
name: mirror-repo
description: Mirror a Git repository between the Forge and external hosts such as GitHub. Use when mirroring a repo into the Forge, or pushing a Forge repo out to GitHub.
---

# Mirror a repo

The Forge (Forgejo, host `forge.tn.ojizero.dev`) is the source of truth. External hosts are backups and public mirrors. Mirrors run in two directions:

- **Mirror in**: the Forge pulls an external repo into the `sovereign` org.
- **Mirror out**: the Forge pushes one of its repos to an external host over SSH.

Input: the repo and the direction. The repo can be just the name of a well-known project: resolve its upstream clone URL yourself. Ask only when the repo or the direction stays unclear.

## Mirror in

```sh
fj -H forge.tn.ojizero.dev repo migrate --mirror <clone-url> sovereign/<name>
```

`<name>` is the upstream repo name. When that name is generic or already taken in `sovereign`, prefix the upstream owner, as in `mattpocock-skills`.

To move one of the user's own repos onto the Forge as its new source of truth, drop `--mirror` and target `ojizero/<name>`. Then mirror it out to its old home.

Done when `fj -H forge.tn.ojizero.dev repo view sovereign/<name>` shows the repo with its default branch.

## Mirror out

`fj` has no push-mirror command, so call the Forgejo API with `fj`'s token. Call it only through this form, which keeps the token out of your context:

```sh
curl -fsS -H @<(jq -r '"Authorization: token " + .hosts["forge.tn.ojizero.dev"].token' ~/.local/share/forgejo-cli/keys.json) \
  https://forge.tn.ojizero.dev/api/v1/<path> [-X POST -H 'Content-Type: application/json' -d '<json>']
```

1. **Target**: GitHub does not create a repo on push. Look it up with `gh repo view ojizero/<name>`. When it is missing, create it with `gh repo create ojizero/<name>`, copying the Forge repo's visibility and description. When it exists, it must share history with the Forge repo: the mirror force-pushes over it.
2. **Push mirror**: `POST repos/<owner>/<name>/push_mirrors` with body:

   ```json
   {"remote_address": "git@github.com:ojizero/<name>.git", "use_ssh": true, "interval": "8h0m0s", "sync_on_commit": true}
   ```

   Forgejo generates the key pair and returns its `public_key`.
3. **Deploy key**: write `public_key` to a scratch file and add it with write access:

   ```sh
   gh repo deploy-key add <file> -R ojizero/<name> -w -t "Forgejo push mirror: <owner>/<name>"
   ```

   For hosts other than GitHub, give the user the public key to add as a deploy key with write access.
4. **Sync**: `POST repos/<owner>/<name>/push_mirrors-sync`, then `GET repos/<owner>/<name>/push_mirrors`.

Done when the mirror's `last_update` is set, its `last_error` is empty, and the target's default branch has the Forge's head commit.
