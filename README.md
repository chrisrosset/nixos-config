# nixos-config

NixOS configurations for the machines in `hosts/`, and Dewclaw configurations for OpenWrt access points in `openwrt/`.

Each host directory is an importable NixOS module:

- `default.nix` contains the host's intentional configuration.
- `hardware-configuration.nix` contains generated machine facts such as filesystems and boot-time kernel modules.
- Additional host-specific files, such as networking configuration, live beside those files.

Reusable configuration lives in `modules/`. Hardware that can move between hosts, such as a keyboard, belongs there rather than in a host's generated hardware configuration.

For example, a channel-based rebuild can use the current host's directory directly:

```console
sudo nixos-rebuild switch -I "nixos-config=./hosts/$(hostname)"
```

## OpenWrt access points

OpenWrt configuration is separate from the NixOS modules:

- [`openwrt/default.nix`](./openwrt/default.nix) pins Dewclaw and builds its deployment scripts.
- [`openwrt/configuration.nix`](./openwrt/configuration.nix) defines the shared AP configuration and per-device settings for `gl-b3000-a` and `gl-b3000-b`.

Build the deployment scripts from the repository root on an `x86_64-linux` machine:

```console
nix-build ./openwrt
```

This creates `result/bin/deploy-gl-b3000-a` and `result/bin/deploy-gl-b3000-b`. Building does not contact or modify the APs. Nixpkgs comes from the local `<nixpkgs>` channel; only Dewclaw is pinned here.

Configuration rationale, ownership, and service behavior are documented alongside the declarations in [`openwrt/configuration.nix`](./openwrt/configuration.nix).

Before deploying, prepare a SOPS-encrypted file whose decrypted JSON object contains:

- `wifi_password`: the existing shared Wi-Fi password.
- `root_password_hash`: a shared SHA-512 crypt root password hash for both APs.

Generate the root password hash locally with `openssl passwd -6` and store the complete result in the encrypted file.

Set `DEWCLAW_SECRETS_FILE` to the encrypted file's path. The deploying user also needs access to the SOPS decryption key. Secrets are decrypted at deployment time, not embedded in Nix outputs. Do not commit plaintext credentials, decryption keys, or unencrypted router backups.

Run deployment on `lemur`, one AP at a time, with a current backup and wired recovery access. Verify management, wireless clients, and DHCP/DNS afterward. This configuration has not yet been deployed through Dewclaw.
