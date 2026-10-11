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
- [`openwrt/configuration.nix`](./openwrt/configuration.nix) defines `router` (Linksys WRT1200AC) and the shared AP configuration for `gl-b3000-a` and `gl-b3000-b`.

Build the deployment scripts from the repository root on an `x86_64-linux` machine:

```console
nix-build ./openwrt
```

This creates `result/bin/deploy-router`, `result/bin/deploy-gl-b3000-a`, and `result/bin/deploy-gl-b3000-b`. Building does not contact or modify the devices. Nixpkgs comes from the local `<nixpkgs>` channel; only Dewclaw is pinned here.

Configuration rationale, ownership, and service behavior are documented alongside the declarations in [`openwrt/configuration.nix`](./openwrt/configuration.nix).

Before deploying any device, use the SOPS-encrypted [`openwrt/secrets.json`](./openwrt/secrets.json), whose decrypted JSON object contains:

- `wifi_password`: the existing shared Wi-Fi password, used only by the APs.
- `root_password_hash`: a shared SHA-512 crypt root password hash for the router and both APs.

Generate the root password hash locally with `openssl passwd -6` and store the complete result in the encrypted file.

Set `DEWCLAW_SECRETS_FILE` to the encrypted file's path. The deploying user also needs access to the SOPS decryption key. Secrets are decrypted at deployment time, not embedded in Nix outputs. Do not commit plaintext credentials, decryption keys, or unencrypted router backups.

The router baseline was verified after upgrading to OpenWrt 25.12.5. Deployment intentionally replaces its root password and authorized keys with the APs' shared password and lemur/ecolite public keys. SSH password login remains disabled on the router; LuCI uses the shared root password.

Run deployment from a host whose SSH keys the target accepts, one device at a time, with a current backup and wired recovery access. Deployment reboots the target; rebooting the main router interrupts Internet access and may interrupt the deployment connection. Verify management, clients, DHCP/DNS, and IPv6 afterward. The AP configuration has been deployed and verified; the router declaration has not yet been deployed.
