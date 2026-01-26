{ config, pkgs, ... }:

# Requires Tailscale to be enabled and running.

{
  services.zabbixAgent = {
    enable = true;
    openFirewall = true;
    server = "morgoth";
  };
}
