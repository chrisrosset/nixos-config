{ config, pkgs, ... }:
let
  postgresqlDomain = "rosset.tech";
  postgresqlCertDir = config.security.acme.certs."${postgresqlDomain}".directory;
  postgresqlCredsDir = "/var/run/credentials/postgresql.service";
in
{
  imports = [
      ./genesis/hardware-configuration.nix
      ./genesis/networking.nix # generated at runtime by nixos-infect
      ./modules/cli.nix
    ];

  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "genesis";
  networking.firewall = {
    enable = false;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  programs.fish.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@rosset.org.uk";
    };
    certs."${postgresqlDomain}".postRun = ''
      systemctl restart postgresql
    '';

    # https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/
    certs."rosset.org.uk" = {
      domain = "rosset.org.uk";
      extraDomainNames = [ "*.rosset.org.uk" ];
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = "/root/ovh-creds-rosset.org.uk.txt";
    };
  };

  services = {
    fail2ban = {
      #enable = true;
    };

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
            root = "/var/www/ewa.rosset.pl";
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

        "rosset.tech" = {
          forceSSL = true;
          enableACME = true;
          serverAliases = [ "www.rosset.tech" ];
          locations."/" = {
            root = "/var/www/rosset.tech";
          };
        };

        "hass.rosset.tech" = {
          forceSSL = true;
          enableACME = true;
          serverAliases = [ "www.hass.rosset.tech" ];
          locations."/" = {
            proxyPass = "http://morgoth:8123";
            proxyWebsockets = true;
          };
        };

      };
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    postgresql = {
      enable = true;
      enableTCPIP = true;
      authentication = ''
        local all all              peer
        hostssl  all all 0.0.0.0/0    scram-sha-256
        hostssl  all all ::0/0        scram-sha-256
      '';
      settings = {
        password_encryption = "scram-sha-256";
        ssl = true;
        ssl_cert_file = "${postgresqlCredsDir}/fullchain.pem";
        ssl_key_file = "${postgresqlCredsDir}/key.pem";
      };
    };

    tailscale = {
      authKeyFile = "/root/tailscale.key";
      enable = true;
      extraUpFlags = [
        "--advertise-exit-node"
        "--ssh"
      ];
      openFirewall = true;
    };
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "21.11";

  systemd.services = {
    postgresql = {
      requires = [
        "acme-finished-${postgresqlDomain}.target"
      ];
      serviceConfig.LoadCredential = [
        "fullchain.pem:${postgresqlCertDir}/fullchain.pem"
        "key.pem:${postgresqlCertDir}/key.pem"
      ];
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ctr = {
    isNormalUser = true;
    group = "users";
    uid = 1000;
    home = "/home/ctr";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
    shell = pkgs.fish;
  };

  users.users.http = {
    isSystemUser = true;
    group = "nogroup";
    extraGroups = [ "acme" ];
  };

  time.timeZone = "UTC";
}
