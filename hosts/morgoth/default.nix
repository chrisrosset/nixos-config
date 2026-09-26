{ config, pkgs, lib, ... }:
let
  domain = "rosset.pl";
  subdomain = "home";
in
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
    mosquitto
    p7zip
    syncthing
    zsh
  ];

  nixpkgs.config = {
    allowUnfree = false;
  };

  networking = rec {
    firewall.enable = false;
    hostName = "morgoth";
  };

  # This is (mostly) copy/pasted from `genesis.nix`. Consider unifying into a module.
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@rosset.org.uk";
    };

    certs."${domain}" = {
      domain = domain;
      extraDomainNames = [ "*.${subdomain}.${domain}" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      environmentFile = "/root/ovh-credentials.txt";
    };

    # https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/
    certs."rosset.org.uk" = {
      domain = "rosset.org.uk";
      extraDomainNames = [ "*.rosset.org.uk" "*.home.rosset.org.uk" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      environmentFile = "/root/ovh-creds-rosset.org.uk.txt";
    };
  };

  services = {

    nginx = {
      enable = true;
      user = "http";

      virtualHosts = {
        # Useful for testing certificates.
        "test.home.rosset.pl" = {
          forceSSL = true;
          useACMEHost = "rosset.pl";
          serverAliases = [ "www.test.home.rosset.pl" ];
          locations."/" = {
            return = "200 '<html><body>It works</body></html>'";
            extraConfig = ''
              default_type text/html;
            '';
          };
        };
      };
    };

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

  users.users.http = {
    isSystemUser = true;
    group = "nogroup";
    extraGroups = [ "acme" ];
  };

  virtualisation.docker.enable = true;
}
