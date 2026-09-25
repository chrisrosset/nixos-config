# nixos-config

NixOS configurations for the machines in `hosts/`.

Each host directory is an importable NixOS module:

- `default.nix` contains the host's intentional configuration.
- `hardware-configuration.nix` contains generated machine facts such as filesystems and boot-time kernel modules.
- Additional host-specific files, such as networking configuration, live beside those files.

Reusable configuration lives in `modules/`. Hardware that can move between hosts, such as a keyboard, belongs there rather than in a host's generated hardware configuration.

For example, a channel-based rebuild can use the current host's directory directly:

```console
sudo nixos-rebuild switch -I "nixos-config=./hosts/$(hostname)"
```
