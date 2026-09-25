{ config, lib, ... }:

# Requires Tailscale to be enabled and running.

lib.mkIf config.roles.server {
  services.zabbixAgent = {
    enable = true;
    openFirewall = true;
    server = "ecolite";
    settings = {
      HostMetadataItem = [ "system.uname" ];
      ServerActive = "ecolite";
    };
  };
}
