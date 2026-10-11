# nixos-config

NixOS configurations for the machines in `hosts/`, and Dewclaw configurations for the OpenWrt router and access points in `openwrt/`.

Each host directory is an importable NixOS module:

- `default.nix` contains the host's intentional configuration.
- `hardware-configuration.nix` contains generated machine facts such as filesystems and boot-time kernel modules.
- Additional host-specific files, such as networking configuration, live beside those files.

Reusable configuration lives in `modules/`. Hardware that can move between hosts, such as a keyboard, belongs there rather than in a host's generated hardware configuration.

For example, a channel-based rebuild can use the current host's directory directly:

```console
sudo nixos-rebuild switch -I "nixos-config=./hosts/$(hostname)"
```

## OpenWrt devices

OpenWrt configuration is separate from the NixOS modules:

- [`openwrt/default.nix`](./openwrt/default.nix) pins Dewclaw and builds its deployment scripts.
- [`openwrt/configuration.nix`](./openwrt/configuration.nix) defines `router` (Linksys WRT1200AC), shared fleet settings, and imports the AP definitions.
- [`openwrt/access-points.nix`](./openwrt/access-points.nix) defines `gl-b3000-a` and `gl-b3000-b`, their Wi-Fi settings, and AP-specific service policies.
- [`openwrt/transition.nix`](./openwrt/transition.nix) temporarily retains the router's old address while switching the LAN to the final subnet.
- [`data/hosts-166.nix`](./data/hosts-166.nix) holds site 166 hostnames, IPv4 host suffixes, and reservation MAC addresses. The OpenWrt configuration derives addresses, reservations, and DNS aliases from this inventory; the LAN prefix and service placement remain there.

Build the deployment scripts from the repository root on an `x86_64-linux` machine:

```console
nix-build ./openwrt
```

This creates `result/bin/deploy-router`, `result/bin/deploy-gl-b3000-a`, and `result/bin/deploy-gl-b3000-b`. Building does not contact or modify the devices. Nixpkgs comes from the local `<nixpkgs>` channel; only Dewclaw is pinned here.

Configuration rationale, ownership, and service behavior are documented alongside the declarations in [`openwrt/configuration.nix`](./openwrt/configuration.nix) and [`openwrt/access-points.nix`](./openwrt/access-points.nix).

Before deploying any device, use the SOPS-encrypted [`openwrt/secrets.json`](./openwrt/secrets.json), whose decrypted JSON object contains:

- `wifi_password`: the existing shared Wi-Fi password, used only by the APs.
- `root_password_hash`: a shared SHA-512 crypt root password hash for the router and both APs.

Generate the root password hash locally with `openssl passwd -6` and store the complete result in the encrypted file.

Set `DEWCLAW_SECRETS_FILE` to the encrypted file's path. The deploying user also needs access to the SOPS decryption key. Secrets are decrypted at deployment time, not embedded in Nix outputs. Do not commit plaintext credentials, decryption keys, or unencrypted router backups.

The router baseline was verified after upgrading to OpenWrt 25.12.5. Deployment intentionally replaces its root password and authorized keys with the APs' shared password and lemur/ecolite public keys. SSH password login remains disabled on the router; LuCI uses the shared root password.
Run deployment from a host whose SSH keys the target accepts, one device at a time, with a current backup and wired recovery access. Deployment reboots the target; rebooting the main router interrupts Internet access and may interrupt the deployment connection.

### IPv4 subnet transition

The final configuration uses `10.166.0.0/24`. Do not deploy it directly to devices
still using `192.168.0.0/24`. First build the router-only transition:

```console
nix-build ./openwrt --arg configuration ./openwrt/transition.nix -o result-transition
```

With a fresh private backup, the usual SOPS environment, and local wired recovery
access, run `./result-transition/bin/deploy-router`. It connects and confirms at
`192.168.0.1`, retains that address on the LAN bridge, and configures the primary
LAN, DHCP pool, reservations, and DNS for `10.166.0.0/24`. It does not provide DHCP
on the old subnet. Existing clients may keep old leases until renewal; the old
address is a recovery aid, not a guarantee that every old client keeps working.
Keep a wired recovery host able to use an unused static `192.168.0.x/24` address.

Renew or reconnect DHCP clients, including each AP individually, and update
manually addressed devices. Verify management, DHCP/DNS, Home Assistant, camera
streams, Zigbee, and Internet access on the new subnet. The router's old address
can still be used to recover clients or fix the configuration.

Once the new addresses work, build the normal configuration with
`nix-build ./openwrt`. Establish SSH trust at the new router IP by verifying it
against the existing trusted host key; do not disable host-key checking. Deploy
the final router configuration from a host on the new subnet to remove
`lan_old`, and deploy AP updates individually if needed. Do not remove old-subnet
access until all required devices have migrated.
