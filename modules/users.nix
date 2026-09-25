{ config, lib, pkgs, ... }:
let
  sshKeys = import ../data/ssh-keys.nix;
in
{
  programs.fish.enable = lib.mkDefault true;

  users.users.ctr = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ] ++ lib.concatMap
      ({ enabled, group }: lib.optional enabled group)
      [
        {
          enabled = config.networking.networkmanager.enable;
          group = "networkmanager";
        }
        {
          enabled = config.virtualisation.docker.enable;
          group = "docker";
        }
        {
          enabled = config.services.transmission.enable;
          group = "transmission";
        }
        {
          enabled = config.virtualisation.virtualbox.host.enable;
          group = "vboxusers";
        }
      ];

    # Override NixOS's Bash default while allowing explicit host shells to win.
    shell = lib.mkOverride 900 pkgs.fish;
    openssh.authorizedKeys.keys = sshKeys.personal;
  };
}