{ config, pkgs, ... }:
let
  # syncthingCfg = import ./modules/syncthing.nix;
  wireguardCfg = import ./modules/wireguard.nix;
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

  # fileSystems = {
  #   # RAID Array
  #   "/mnt/raid" = {
  #     label = "data";
  #     fsType = "ext4";
  #   };

  #   # Network binds
  #   "/exports/movies" = {
  #     device = "/mnt/raid/movies";
  #     options = [ "bind" ];
  #   };

  #   "/exports/photos" = {
  #     device = "/mnt/raid/photos";
  #     options = [ "bind" ];
  #   };

  #   "/exports/random" = {
  #     device = "/mnt/raid/random";
  #     options = [ "bind" ];
  #   };

  #   "/exports/series" = {
  #     device = "/mnt/raid/series";
  #     options = [ "bind" ];
  #   };
  # };

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  networking = rec {
    firewall.enable = false;
    hostName = "kraken";
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

    # TODO: remove before committing
    rsyncd = {
      enable = true;
      settings = {
        export = {
          path = "/srv/raid/export";
          "dont compress" = "*";
        };
      };
    };

    samba = {
      enable   = true;
      nsswins  = true;
      extraConfig = ''
workgroup = WORKGROUP
server string = Home server
security = user
map to guest = Bad User
guest account = nobody

[export]
  path = /srv/raid/export
  public = yes
  only guest = yes
  writable = yes
'';
    };

  #   syncthing = {
  #     enable = true;
  #     openDefaultPorts = true;
  #     user = "ctr";
  #     dataDir = "/mnt/raid/syncthing/";
  #     configDir = "/home/ctr/.config/syncthing";

  #     declarative = {
  #       overrideDevices = true;
  #       devices = syncthingCfg.devices;

  #       overrideFolders = true;
  #       folders = {
  #         "/mnt/raid/syncthing/default" = {
  #           id = "sync-default";
  #           label = "Default";
  #           devices = syncthingCfg.groups.standard;
  #         };

  #         "/mnt/raid/syncthing/Calibre" = {
  #           id = "sync-calibre";
  #           label = "Calibre";
  #           devices = syncthingCfg.groups.pcs;
  #         };

  #         "/mnt/raid/syncthing/s71-photos" = {
  #           id = "sm-a715f_ntzx-photos";
  #           label = "S71 Photos";
  #           devices = [ "s71a" ];
  #           type = "receiveonly";
  #         };
  #       };
  #     };
  #   };
  };

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
