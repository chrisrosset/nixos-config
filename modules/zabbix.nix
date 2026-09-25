{ config, lib, pkgs, ... }:
let
  # Initializes the Admin password and keeps Linux host auto-registration configured.
  bootstrap = pkgs.writeScriptBin "zabbix-bootstrap" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./zabbix-bootstrap.py}
  '';
in

lib.mkMerge [
  # Requires Tailscale to be enabled and running.
  (lib.mkIf config.roles.server {
    services.zabbixAgent = {
      enable = true;
      openFirewall = true;
      server = "ecolite";
      settings = {
        HostMetadataItem = [ "system.uname" ];
        ServerActive = "ecolite";
      };
    };
  })


  (lib.mkIf config.services.zabbixWeb.enable {
    # https://github.com/NixOS/nixpkgs/issues/417572
    services.phpfpm.pools.zabbix.phpPackage = pkgs.php83;

    # Retrieve the generated frontend password with:
    # sudo cat /root/zabbix-admin-password
    systemd.services.zabbix-bootstrap = {
      description = "Configure Zabbix auto-registration";
      after = [
        "nginx.service"
        "phpfpm-zabbix.service"
        "zabbix-server.service"
      ];
      requires = [
        "nginx.service"
        "phpfpm-zabbix.service"
        "zabbix-server.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.getExe bootstrap;
        Restart = "on-failure";
        RestartSec = "10s";
        Type = "oneshot";
        UMask = "0077";
      };
    };
  })
]
