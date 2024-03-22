{ config, pkgs, lib, ... }:
let
  syncthingCfg = import ./modules/syncthing.nix;
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports = [
      ./hardware/morgoth.nix
      ./modules/cli.nix
    ];

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    mosquitto
    p7zip
    syncthing
    zsh
  ];

  hardware.pulseaudio.enable = true;

  nixpkgs.config = {
    allowUnfree = false;
  };

  networking = rec {
    firewall.enable = false;
    hostName = "morgoth";
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

  programs = {
    fish.enable = true;
  };

  services = {
    openssh.enable = true;

    samba = {
      enable   = true;
      nsswins  = true;
      extraConfig = ''
workgroup = WORKGROUP
server string = Home server
security = user
map to guest = Bad User
guest account = nobody

[movies]
  path = /srv/raid/movies
  public = yes
  only guest = yes
  writable = yes

[photos]
  path = /srv/raid/photos
  public = yes
  only guest = yes
  writable = yes

[photos-kraken]
  path = /srv/raid/photos-kraken
  public = yes
  only guest = yes
  writable = no

[random]
  path = /srv/raid/random
  public = yes
  only guest = yes
  writable = yes

[series]
  path = /srv/raid/series
  public = yes
  only guest = yes
  writable = yes
'';
    };

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";
      guiAddress = "0.0.0.0:8384";

      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = syncthingCfg.devices;
        folders = {
          "/home/ctr/syncthing/default" = {
            id = "sync-default";
            label = "Default";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/opo-photos" = {
            id = "cph2551_fhbe-photos";
            label = "OnePlus Open Photos";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/a71-photos" = {
            id = "sm-a715f_ntzx-photos";
            label = "A71 Photos";
            devices = [ "morgoth" "s71a" ];
          };

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };

    tailscale = {
      authKeyFile = "/root/tailscale.key";
      enable = true;
      openFirewall = true;
    };

    udev = {
      enable = true;
      extraRules = ''
      # After the occasional USB disconnect/reconnect from the Zigbee adapter,
      # automatically restart `zigbee2mqtt`.
      SUBSYSTEM=="usb", ATTRS{idProduct}=="ea60", ATTRS{idVendor}=="10c4", ACTION=="bind", RUN+="${pkgs.docker}/bin/docker restart zigbee2mqtt"
    '';
    };
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "21.11";

  systemd.services."tune-usb-autosuspend" = {
      description = "Disable USB autosuspend";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "oneshot"; };
      unitConfig.RequiresMountsFor = "/sys";
      script = ''
        echo -1 > /sys/module/usbcore/parameters/autosuspend
      '';
    }; 

  time.timeZone = "America/New_York";

  #users.mutableUsers = false;
  users.extraUsers.ctr = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "dialout" "docker" "wheel" ];
    createHome = true;
    home = "/home/ctr";
    uid = 1000;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  virtualisation.docker.enable = true;
}
