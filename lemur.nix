{ config, lib, pkgs, ... }:

let
  syncthingCfg = import ./modules/syncthing.nix;
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports = [
    ./hardware/filco-jp.nix
    ./hardware/lemur.nix
    ./modules/cli.nix
    ./modules/fonts.nix
    ./modules/games.nix
    ./modules/kde.nix
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    alacritty
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    avahi
    calibre
    ((emacsPackagesNgGen emacs).emacsWithPackages (epkgs: with epkgs.melpaPackages; [
      forge
      plantuml-mode
      vterm
    ]))
    firefox
    ghidra-bin
    graphviz-nox
    libvterm-neovim
    keepassxc
    plantuml
    sqlite
    vlc
  ];

  networking = rec {
    hostName = "lemur";
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable the Plasma 5 Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;

    layout = "us";
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        disableWhileTyping = false;
      };
    };

    videoDrivers = [ "modesetting" ];
    useGlamor = true;
  };

  services = {
    acpid.enable = true;
    fstrim.enable = true;
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

