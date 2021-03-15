{ config, pkgs, ... }:

let
  syncthingCfg = import ./modules/syncthing.nix;
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports =
    [
      ./hardware/prometheus.nix
      ./modules/cli.nix
      #./monit.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  environment.systemPackages = with pkgs; [
      cron
      docker
      fortune
      mosquitto
      samba
      zsh
  ];

  fileSystems = {
    # RAID Array
    "/mnt/raid" = {
      label = "data";
      fsType = "ext4";
    };

    # Network binds
    "/exports/movies" = {
      device = "/mnt/raid/movies";
      options = [ "bind" ];
    };

    "/exports/photos" = {
      device = "/mnt/raid/photos";
      options = [ "bind" ];
    };

    "/exports/random" = {
      device = "/mnt/raid/random";
      options = [ "bind" ];
    };

    "/exports/series" = {
      device = "/mnt/raid/series";
      options = [ "bind" ];
    };
  };

  hardware.bluetooth.enable = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  networking = rec {
    firewall.enable = false;
    hostName = "prometheus";
    hostId = "428dc8b7";
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

  security.sudo.enable = true;

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
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
      permitRootLogin = "yes";
    };

    ntp.enable = true;

    samba = {
      enable   = true;
      nsswins  = true;
      extraConfig = ''
workgroup = WORKGROUP
server string = Home server
security = user
map to guest = Bad User
guest account = nobody

[movies]
  path = /exports/movies
  public = yes
  only guest = yes
  writable = yes

[photos]
  path = /exports/photos
  public = yes
  only guest = yes
  writable = yes

[photos-kraken]
  path = /mnt/raid/photos-kraken
  public = yes
  only guest = yes
  writable = no

[random]
  path = /exports/random
  public = yes
  only guest = yes
  writable = yes

[series]
  path = /exports/series
  public = yes
  only guest = yes
  writable = yes
'';
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "ctr";
      dataDir = "/mnt/raid/syncthing/";
      configDir = "/home/ctr/.config/syncthing";

      declarative = {
        overrideDevices = true;
        devices = syncthingCfg.devices;

        overrideFolders = true;
        folders = {
          "/mnt/raid/syncthing/default" = {
            id = "sync-default";
            label = "Default";
            devices = syncthingCfg.groups.standard;
          };

          "/mnt/raid/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };
  };

  time.timeZone = "UTC";

  users.extraUsers = {
    ctr = {
      isNormalUser = true;
      uid = 1000;
      shell = "${pkgs.zsh}/bin/zsh";
      extraGroups = [ "wheel" "nogroup" ];
      openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
    };

    hass.isNormalUser = true;
  };
  virtualisation.docker.enable = true;
}
