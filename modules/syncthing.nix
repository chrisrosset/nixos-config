{ config, lib, ... }:
let
  syncthingData = import ../data/syncthing.nix;
in
{
  imports = [ ./syncthing-folders.nix ];

  config = lib.mkIf config.services.syncthing.enable {
    services.syncthing = {
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = lib.mkDefault "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";

      # Restrict the administrative GUI to loopback; binding it to all
      # interfaces would expose it too broadly. For remote access, use an SSH
      # tunnel, for example: ssh -L 18384:127.0.0.1:8384 ctr@morgoth
      # Then open http://127.0.0.1:18384.
      guiAddress = "127.0.0.1:8384";

      settings.devices = syncthingData.devices;
    };
  };
}
