{ config, pkgs, ... }:
let
  syncthingCfg = import ./modules/syncthing.nix;
in
{
  imports =
    [
      ./hardware/kraken.nix
      ./modules/cli.nix
    ];

  environment.systemPackages = with pkgs; [
      cron
      fish
      samba
      zsh
  ];

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  networking = rec {
    firewall.enable = false;
    hostName = "kraken";
  };

  programs.fish.enable = true;

  security.sudo.enable = true;

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
        domain = true;
      };
    };

    cron.enable = true;

    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };

    ntp.enable = true;

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";
      key = "/root/syncthing/key.pem";
      cert = "/root/syncthing/cert.pem";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = syncthingCfg.devices;
        folders = {
          "/home/ctr/syncthing/default" = {
            id = "sync-default";
            label = "Default";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };

    tailscale = {
      authKeyFile = "/root/tailscale.key";
      enable = true;
      extraUpFlags = [ "--advertise-exit-node" "--ssh" ];
      useRoutingFeatures = "both";
    };
  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

  time.timeZone = "UTC";

  users.extraUsers = {
    ctr = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" "nogroup" ];
      uid = 1000;
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
    };

    hass.isNormalUser = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
