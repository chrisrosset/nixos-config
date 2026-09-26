{ config, pkgs, ... }:
let
  transmissionPath = "/srv/raid/export/transmission";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
    ];

  roles.server = true;

  networking = rec {
    firewall.enable = false;
    hostName = "tiamat";
  };

  services = {
    syncthing = {
      enable = true;
      dataDir = "/srv/raid/export/syncthing";
      key = "/root/syncthing/key.pem";
      cert = "/root/syncthing/cert.pem";
    };

    samba = {
      enable = true;
      nsswins = true;
      openFirewall = true;

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
