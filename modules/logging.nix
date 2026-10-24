{ config, lib, options, ... }:
let
  logging = import ../data/logging.nix;
in
{
  config = lib.mkIf config.roles.server {
    # Newer nixpkgs uses structured settings; NixOS 26.05 uses storage/extraConfig.
    services.journald = (if options.services.journald ? settings then {
      settings.Journal = {
        Storage = "persistent";
        SystemMaxUse = "512M";
      };
    } else {
      storage = "persistent";
      extraConfig = ''
        SystemMaxUse=512M
      '';
    }) // {
      upload = {
        enable = true;
        settings.Upload = {
          URL = "http://${logging.host.hostname}:${toString logging.ports.http}/insert/journald";
          NetworkTimeoutSec = "30s";
        };
      };
    };
  };
}
