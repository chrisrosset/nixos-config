{ config, pkgs, ... }:
{
  imports = [
      ./hardware-configuration.nix
      ./networking.nix # generated at runtime by nixos-infect
      ../../modules/base.nix
    ];

  roles.server = true;

  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "genesis";
  networking.firewall = {
    enable = false;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@rosset.org.uk";
    };

    # https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/
    certs."rosset.org.uk" = {
      domain = "rosset.org.uk";
      extraDomainNames = [ "*.rosset.org.uk" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      environmentFile = "/root/ovh-credentials.txt";
    };

    certs."rosset.pl" = {
      domain = "rosset.pl";
      extraDomainNames = [ "*.rosset.pl" "*.home.rosset.pl" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      environmentFile = "/root/ovh-credentials.txt";
    };
  };

  services = {

    nginx = {
      enable = true;
      user = "http";
      virtualHosts = {

        "aleksandra.rosset.pl" = {
          serverAliases = [ "www.aleksandra.rosset.pl" ];
          locations."/" = {
            return = "301 http://aleksandrarosset.myportfolio.com";
          };
        };

        "ewa.rosset.pl" = {
          serverAliases = [ "www.ewa.rosset.pl" ];
          locations."/" = {
            return = "301 https://www.linkedin.com/in/ewa-rosset-6a838a82/";
          };
        };

        "rosset.org.uk" = {
          forceSSL = true;
          useACMEHost = "rosset.org.uk";
          serverAliases = [ "www.rosset.org.uk" ];
          locations."/" = {
            root = "/var/www/rosset.org.uk";
          };
        };

        "ha.home.rosset.pl" = {
          forceSSL = true;
          useACMEHost = "rosset.pl";
          serverAliases = [ "www.ha.home.rosset.pl" ];
          locations."/" = {
              proxyPass = "http://morgoth:8123";
              proxyWebsockets = true;
          };
        };

      };
    };

  };

  system.stateVersion = "25.11";

  users.users.http = {
    isSystemUser = true;
    group = "nogroup";
    extraGroups = [ "acme" ];
  };

  time.timeZone = "UTC";
}
