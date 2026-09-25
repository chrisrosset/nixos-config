{ config, pkgs, lib, ... }:
let
  ports = {
    homeassistant = 8123;
    syncthing = 8384;
    zigbee2mqtt = 8080;
  };

  domain = "rosset.pl";
  subdomain = "home";

  mkVirtualHost = svc: port: {
    name = "${svc}.${subdomain}.${domain}";
    value = {
      forceSSL = true;
      useACMEHost = domain;
      serverAliases = [ "www.${svc}.${subdomain}.${domain}" ];
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        proxyWebsockets = true;
      };
    };
  };

  syncthingCfg = import ../../modules/syncthing.nix;
in
{
  imports = [
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
      credentialsFile = "/root/ovh-credentials.txt";
    };

    # https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/
    certs."rosset.org.uk" = {
      domain = "rosset.org.uk";
      extraDomainNames = [ "*.rosset.org.uk" "*.home.rosset.org.uk" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = "/root/ovh-creds-rosset.org.uk.txt";
    };
  };

  services = {

    nginx = {
      enable = true;
      user = "http";

      virtualHosts = builtins.listToAttrs (map (x: mkVirtualHost x.svc x.port) [
        { svc = "ha"; port = ports.homeassistant; }
        { svc = "z2m"; port = ports.zigbee2mqtt; }
      ]) // {

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

        # "fake" .lan domains
        "home-assistant-host.lan" = {
          serverAliases = [ "www.home-assistant-host.lan" ];
          locations."/" = {
            proxyPass = "http://localhost:${toString ports.homeassistant}";
            proxyWebsockets = true;
          };
        };

        "zigbee2mqtt-host.lan" = {
          serverAliases = [ "www.zigbee2mqtt-host.lan" ];
          locations."/" = {
            proxyPass = "http://localhost:${toString ports.zigbee2mqtt}";
            proxyWebsockets = true;
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

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";
      guiAddress = "0.0.0.0:${toString ports.syncthing}";

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

          "/home/ctr/syncthing/opo-photos" = {
            id = "cph2551_fhbe-photos";
            label = "OnePlus Open Photos";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/a71-photos" = {
            id = "sm-a715f_ntzx-photos";
            label = "A71 Photos";
            devices = [ "morgoth" "s71a" ];
          };

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
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
