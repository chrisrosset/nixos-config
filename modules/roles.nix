{ lib, ... }:
{
  options.roles.server = lib.mkEnableOption "server-specific configuration";
}