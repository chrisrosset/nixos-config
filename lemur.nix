{ config, pkgs, ... }:

let
  syncthingCfg = import ./modules/syncthing.nix;
in
{
  imports = [
    ./hardware/filco-jp.nix
    ./hardware/lemur.nix
    ./modules/cli.nix
    ./modules/fonts.nix
    ./modules/kde.nix
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    alacritty
    calibre
    emacs
    firefox
    keepassxc
    sqlite
  ];

  networking.hostName = "lemur";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable the Plasma 5 Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;

    layout = "us";
    libinput = {
      enable = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };

    videoDrivers = [ "modesetting" ];
    useGlamor = true;
  };

  services = {
    acpid.enable = true;
    openssh.enable = true;

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";

      declarative = {
        overrideDevices = true;
        devices = syncthingCfg.devices;
        overrideFolders = true;
        folders = {
          "/home/ctr/syncthing/default" = {
            id = "sync-default";
            label = "Default";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };

    tlp.enable = true;
  };

  users.users.ctr = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    home = "/home/ctr";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  system.stateVersion = "20.09"; # change with care

  time.timeZone = "America/New_York";
}

