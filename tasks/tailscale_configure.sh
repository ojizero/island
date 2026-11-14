#!/bin/sh

# On DSM 7 the Tailscale package has no permission to create a TUN
# device, so apps on Atlas cannot open connections to the tailnet
# (inbound works). `configure-host` gives that permission. Added as a
# "boot up" triggered task that runs as root. Run it again after each
# Tailscale package upgrade.
#
# Ref: https://tailscale.com/docs/integrations/synology#enable-outbound-connections

/var/packages/Tailscale/target/bin/tailscale configure-host

synosystemctl restart pkgctl-Tailscale.service
