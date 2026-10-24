{ lib, ... }:
{
  imports = [
    ./logging.nix
    ./zabbix.nix
  ];

  options.roles.server = lib.mkEnableOption "server-specific configuration";
}