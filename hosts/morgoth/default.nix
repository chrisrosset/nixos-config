{ pkgs, ... }:
{
  imports = [
      ./hardware-configuration.nix
      ../../modules/base.nix
    ];

  roles.server = true;

  environment.systemPackages = with pkgs; [
    (aspellWithDicts (dicts: with dicts; [
      en
      en-computers
      pl
    ]))
    emacs
  ];

  networking = rec {
    firewall.enable = false;
    hostName = "morgoth";
  };

  services = {
    samba = {
      enable   = true;
      nsswins  = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "Home server";
          "security" = "user";
          "map to guest" = "Bad User";
          "guest account" = "nobody";
        };

        "movies" = {
          "path" = "/srv/raid/movies";
          "public" = "yes";
          "only guest" = "yes";
          "writable" = "yes";
        };

        "photos" = {
          "path" = "/srv/raid/photos";
          "public" = "yes";
          "only guest" = "yes";
          "writable" = "yes";
        };

        "photos-kraken" = {
          "path" = "/srv/raid/photos-kraken";
          "public" = "yes";
          "only guest" = "yes";
          "writable" = "yes";
        };

        "random" = {
          "path" = "/srv/raid/random";
          "public" = "yes";
          "only guest" = "yes";
          "writable" = "yes";
        };

        "series" = {
          "path" = "/srv/raid/series";
          "public" = "yes";
          "only guest" = "yes";
          "writable" = "yes";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    syncthing = {
      enable = true;
    };

  };

  system.stateVersion = "25.11";

  time.timeZone = "America/New_York";

  virtualisation.docker.enable = true;
}
