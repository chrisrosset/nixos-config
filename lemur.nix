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

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  ];


  environment.systemPackages = with pkgs; [
    alacritty
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    avahi
    calibre
    chromium
    dbeaver
    docker-compose
    ((emacsPackagesFor emacs).emacsWithPackages (epkgs: with epkgs.melpaPackages; [
      forge
      plantuml-mode
      vterm
    ]))
    firefox
    ghidra-bin
    graphviz-nox
    guile_3_0
    guile-json
    guile-gcrypt
    libreoffice-fresh
    libvterm-neovim
    keepassxc
    kitty
    nix-direnv
    nodePackages.mermaid-cli
    plantuml
    signal-desktop
    sbcl
    sqlite
    vlc
  ];

  networking = rec {
    hostName = "lemur";
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

  programs = {
    zsh.enable = true;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable the Plasma 5 Desktop Environment.
    displayManager.sddm = {
      enable = true;
      settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
    };
    desktopManager.plasma5.enable = true;

    layout = "us";
    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = false;
        naturalScrolling = true;
        tapping = true;
      };
    };

    videoDrivers = [ "modesetting" ];
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

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };

    # https://discourse.nixos.org/t/cant-enable-tlp-when-upgrading-to-21-05/13435/7
    # services.power-profiles-daemon.enable = true;
    #tlp.enable = true;
  };

  users.users.ctr = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    home = "/home/ctr";
    extraGroups = [ "docker" "wheel" "networkmanager" "vboxusers" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  virtualisation = {
    docker.enable = true;
    # virtualbox.host.enable = true;
  };

  system.stateVersion = "20.09"; # change with care

  time.timeZone = "America/New_York";
}

