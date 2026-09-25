{ lib, ... }:
{
  imports = [ ./zabbix.nix ];

  options.roles.server = lib.mkEnableOption "server-specific configuration";
}