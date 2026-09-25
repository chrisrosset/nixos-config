# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware/ecolite.nix
      ./modules/cli.nix
    ];

  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hostName = "ecolite";

  networking.networkmanager.enable = true;

  users.users.ctr = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  environment.systemPackages = with pkgs; [
  ];

  services = {
    openssh.enable = true;

    tailscale = {
      authKeyFile = "/root/tailscale.key";
      enable = true;
      extraSetFlags = [ "--ssh" ];
      extraUpFlags = [ "--advertise-exit-node" ];
      openFirewall = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "26.05"; # Did you read the comment?

  time.timeZone = "America/New_York";
}

