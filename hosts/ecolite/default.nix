# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  domain = "rosset.pl";
  subdomain = "home";

  ports = {
    homeassistant = 8123;
    syncthing = 8384;
    vaultwarden = 8006;
    zabbix = 8081;
    zigbee2mqtt = 8080;
  };

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
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/cli.nix
      ../../modules/nix.nix
      ../../modules/roles.nix
      ../../modules/ssh.nix
      ../../modules/tailscale.nix
      ../../modules/users.nix
    ];

  roles.server = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "ecolite";
    networkmanager.enable = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@rosset.org.uk";
    };

    certs."${domain}" = {
      domain = domain;
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      environmentFile = "/root/ovh-credentials.txt";
      extraDomainNames = [ "*.${subdomain}.${domain}" ];
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

  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  system.stateVersion = "26.05";

  time.timeZone = "America/New_York";

  users.users.http = {
    isSystemUser = true;
    group = "nogroup";
    extraGroups = [ "acme" ];
  };

  virtualisation.docker.enable = true;
}
