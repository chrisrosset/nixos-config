{ config, lib, ... }:
let
  syncthingData = import ../data/syncthing.nix;
  hostName = config.networking.hostName;

  # Keep folder paths tied to each host's storage root.
  dataDir = config.services.syncthing.dataDir;

  # `hosts` controls where NixOS configures the folder. `devices` controls
  # which Syncthing peers the configured folder is shared with.
  folder = hosts: devices: {
    enable = builtins.elem hostName hosts;
    inherit devices;
  };
in
{
  config = lib.mkIf config.services.syncthing.enable {
    services.syncthing.settings.folders = {
      "${dataDir}/default" = folder syncthingData.groups.pcs syncthingData.groups.standard // {
        id = "sync-default";
        label = "Default";
      };

      "${dataDir}/Calibre" = folder syncthingData.groups.pcs syncthingData.groups.pcs // {
        id = "sync-calibre";
        label = "Calibre";
      };

      "${dataDir}/opo-photos" = folder [ "morgoth" ] syncthingData.groups.standard // {
        id = "cph2551_fhbe-photos";
        label = "OnePlus Open Photos";
      };

      "${dataDir}/a71-photos" = folder [ "morgoth" ] [ "morgoth" "s71a" ] // {
        id = "sm-a715f_ntzx-photos";
        label = "A71 Photos";
      };
    };
  };
}
