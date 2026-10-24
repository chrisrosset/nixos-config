{ config, lib, options, ... }:
{
  config = lib.mkIf config.roles.server {
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
          URL = "http://ecolite:9428/insert/journald";
          NetworkTimeoutSec = "30s";
        };
      };
    };
  };
}
