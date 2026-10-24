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

OpenWrt configuration is separate from the NixOS modules because the network
devices don't actually run Nix. Instead, I use [DewClaw](https://github.com/MakiseKurisu/dewclaw)
to expressing the setup in Nix. DewClaw compiles those into scripts which do
the actual setup.

Build the deployment scripts from the repository root on an `x86_64-linux` machine:

```console
nix-build ./openwrt
```

This creates the deployment scripts in `result/bin/`.

Before deploying any device, use the SOPS-encrypted [`openwrt/secrets.json`](./openwrt/secrets.json),
whose decrypted JSON object contains:

- `wifi_password`: the existing shared Wi-Fi password, used only by the APs.
- `root_password_hash`: a shared SHA-512 crypt root password hash for the router and both APs.

Set `DEWCLAW_SECRETS_FILE` to the encrypted file's path. The deploying user also needs access to the SOPS decryption key. Secrets are decrypted at deployment time, not embedded in Nix outputs. Do not commit plaintext credentials, decryption keys, or unencrypted router backups.

## Logging

```
NixOS servers (including ecolite)       Router + access points
  system logs + Docker logs*            Zigbee coordinator
             |                          Zigbee2MQTT (native syslog)
          journald                                 |
             |                                     |
    systemd-journal-upload                         |
             |                                     |
             | HTTP :9428                          | TCP/UDP syslog
             |                                     |
       +-----|--------------- ecolite -------------|-------+
       |     |                                     |       |
       |     v                                     v       |
       |  VictoriaLogs <--- HTTP/JSON --- Vector :1514     |
       |       ^                                           |
       |       |                                           |
       |     nginx                                         |
       +-------|-------------------------------------------+
               |
    https://logs.home.rosset.pl
           UI / query API

* Only containers using Docker's journald logging driver.
```
