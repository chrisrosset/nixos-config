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

  environment.systemPackages = with pkgs; [
    docker
  ];

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
        # WAIT: port services over from morgoth when ready
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
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "26.05"; # Did you read the comment?

  time.timeZone = "America/New_York";

  users.users = {
    ctr = {
      isNormalUser = true;
      extraGroups = [ "docker" "wheel" ];
      openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
    };

    http = {
      isSystemUser = true;
      group = "nogroup";
      extraGroups = [ "acme" ];
    };
  };

  virtualisation.docker.enable = true;
}
