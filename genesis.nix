{ config, pkgs, ... }:
let
  postgresqlDomain = "rosset.tech";
  postgresqlCertDir = config.security.acme.certs."${postgresqlDomain}".directory;
  postgresqlCredsDir = "/var/run/credentials/postgresql.service";
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports = [
      ./genesis/hardware-configuration.nix
      ./genesis/networking.nix # generated at runtime by nixos-infect
      ./modules/cli.nix
    ];

  boot.cleanTmpDir = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "genesis";
  networking.firewall = {
    enable = false;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 wireguardCfg.serverPort ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "192.168.200.1/24" ];
      listenPort = wireguardCfg.serverPort;
      privateKeyFile = "/root/wireguard/genesis.key";

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
      '';

      peers = wireguardCfg.getServerPeers "/root/wireguard";
    };
  };

  security.acme = {
    acceptTerms = true;
    email = "chris@rosset.org.uk";
    certs."${postgresqlDomain}".postRun = ''
      systemctl restart postgresql
    '';
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
            proxyPass = "http://192.168.200.10:8123";
            proxyWebsockets = true;
          };
        };

      };
    };

    openssh = {
      enable = true;
      permitRootLogin = "no";
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
  };

  users.users.http = {
    isSystemUser = true;
  };

  time.timeZone = "UTC";
}
