{ config, pkgs, ... }:
let
  syncthingCfg = import ../../modules/syncthing.nix;
  transmissionPath = "/srv/raid/export/transmission";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/cli.nix
      ../../modules/nix.nix
      ../../modules/roles.nix
      ../../modules/ssh.nix
      ../../modules/tailscale.nix
      ../../modules/users.nix
    ];

  roles.server = true;

  environment.systemPackages = with pkgs; [
      cron
      fish
      samba
      zsh
  ];

  networking = rec {
    firewall.enable = false;
    hostName = "tiamat";
  };

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

    ntp.enable = true;

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/srv/raid/export/syncthing";
      configDir = "/home/ctr/.config/syncthing";
      guiAddress = "0.0.0.0:8384";
      key = "/root/syncthing/key.pem";
      cert = "/root/syncthing/cert.pem";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = syncthingCfg.devices;
        folders = {
          "/srv/raid/export/syncthing/tidemill-sync" = {
            id = "tidemill-sync";
            label = "tidemill-sync";
            devices = [ "tiamat" "tidemill" ];
          };
        };
      };
    };

    samba = {
      enable = true;
      nsswins = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "tiamat";
          "netbios name" = "tiamat";
          "security" = "user";
          # "use sendfile" = "yes";
          # "max protocol" = "smb2";
          # localhost includes the IPv6 loopback address, ::1.
          "hosts allow" = "0.0.0.0/0 192.168.0. 127.0.0.1 localhost";
          # "hosts deny" = "0.0.0.0/0";
          "guest account" = "ctr";
          "map to guest" = "bad user";
        };

        export = {
          "path" = "/srv/raid/export";
          "browseable" = "yes";
          "writeable" = "yes";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "ctr";
          "force group" = "nogroup";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    transmission = {
      package = pkgs.transmission_4;
      enable = true;

      settings = {
        download-dir = "${transmissionPath}/downloads";
        incomplete-dir = "${transmissionPath}/incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
        watch-dir = "${transmissionPath}/watch";
        watch-dir-enabled = true;

      };
    };
  };

  time.timeZone = "UTC";

  system.stateVersion = "22.11";
}
