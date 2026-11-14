#!/bin/sh

# DSM's kernel limits each user to 8192 inotify watches. Jellyfin
# alone needs about 33000 (its config tree twice, plus the libraries),
# so its library watchers fail and new media waits for a scan. Raise
# the limit, never lower it. Added as a "boot up" triggered task
# that runs as root. See OPERATIONS.md, "media".

set -eu

target=131072

if [ "$(sysctl -n fs.inotify.max_user_watches)" -lt "$target" ]; then
	sysctl -w fs.inotify.max_user_watches="$target"
fi
