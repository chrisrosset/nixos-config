# Baseline configuration shared by every host.
# Hardware and host-specific modules remain in each host's default.nix.
{ config, lib, pkgs, ... }:
{
  imports = [
    ./cli.nix
    ./nginx.nix
    ./nix.nix
    ./roles.nix
    ./ssh.nix
    ./syncthing.nix
    ./tailscale.nix
    ./users.nix
  ];

  # Placeholder until alerting is configured; prevents mdmonitor's missing notification warning.
  boot.swraid.mdadmConf = lib.mkIf config.boot.swraid.enable ''
    PROGRAM ${pkgs.coreutils}/bin/true
  '';
}
