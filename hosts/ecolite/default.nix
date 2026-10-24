# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  domain = "rosset.pl";
  subdomain = "home";

  ports = {
    homeassistant = 8123;
    logs = 9428;
    mosquitto = 1883;
    samba = 445;
    syslog = 1514;
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
      ./syslog.nix
      ../../modules/base.nix
    ];

  roles.server = true;

  boot = {
    kernel.sysctl."vm.swappiness" = 10;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  swapDevices = [{
    device = "/swapfile";
    size = 4096;
  }];

  networking = {
    hostName = "ecolite";
    firewall = {
      enable = true;
      interfaces = lib.genAttrs [ "enp1s0" "tailscale0" ] (_: {
        allowedTCPPorts = [
          ports.samba
          ports.homeassistant
          ports.logs
          ports.mosquitto
          ports.syslog
          ports.zabbix
          ports.zigbee2mqtt
        ];
        allowedUDPPorts = [ ports.syslog ];
      });
    };
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
    victorialogs = {
      enable = true;
      listenAddress = ":${toString ports.logs}";
      extraOptions = [
        "-retention.maxDiskSpaceUsageBytes=32GiB"
        "-retentionPeriod=100y"
        "-journald.streamFields=_MACHINE_ID,_HOSTNAME,_SYSTEMD_UNIT,CONTAINER_NAME"
      ];
    };

    tailscale.extraSetFlags = [ "--advertise-routes=10.166.0.0/24" ];

    samba = {
      enable = true;
      # Opens unnecessary NetBIOS ports on all interfaces.
      openFirewall = false;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server min protocol" = "SMB3_00";
          "smb ports" = toString ports.samba;
          "map to guest" = "Bad User";
          "guest account" = "nobody";
        };
        public = {
          path = "/mnt/cache/data/public";
          "guest ok" = "yes";
          "read only" = "yes";
        };
        data = {
          path = "/mnt/cache/data";
          "guest ok" = "no";
          "valid users" = "ctr";
          "read only" = "no";
        };
      };
    };

    nginx = {
      enable = true;
      user = "http";

      virtualHosts = builtins.listToAttrs (map (x: mkVirtualHost x.svc x.port) [
        { svc = "ha"; port = ports.homeassistant; }
        { svc = "z2m"; port = ports.zigbee2mqtt; }
        { svc = "zabbix"; port = ports.zabbix; }
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

    syncthing.enable = true;

    zabbixServer = {
      enable = true;
      openFirewall = true;
    };
    zabbixWeb = {
      enable = true;
      frontend = "nginx";
      nginx.virtualHost = {
        # Override the default (80) to avoid clashing with the common nginx
        # instance used as a reverse proxy.
        listen = [{ port = ports.zabbix; addr = "0.0.0.0"; }];
      };
    };
  };

  systemd.services.systemd-journal-upload = {
    wants = [ "victorialogs.service" ];
    after = [ "victorialogs.service" ];
  };

  systemd.services.samba-smbd = {
    # The cache mount is optional at boot, but must exist before sharing data.
    unitConfig.RequiresMountsFor = [ "/mnt/cache" ];
    preStart = ''
      test -d /mnt/cache/data
      ${pkgs.coreutils}/bin/install -d -m 0755 -o ctr -g users /mnt/cache/data/public
      # Grant guest traversal without listing private parent directories.
      ${pkgs.acl}/bin/setfacl -m u:nobody:--x /mnt/cache /mnt/cache/data
      ${pkgs.acl}/bin/setfacl -m u:nobody:r-x,d:u:nobody:r-x /mnt/cache/data/public
    '';
  };

  system.stateVersion = "26.05";

  time.timeZone = "America/New_York";

  users.users.http = {
    isSystemUser = true;
    group = "nogroup";
    extraGroups = [ "acme" ];
  };

  virtualisation.docker.enable = true;
}
