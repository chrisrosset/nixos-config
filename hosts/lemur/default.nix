{ config, lib, pkgs, ... }:

let
  syncthingCfg = import ../../modules/syncthing.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/filco-jp.nix
    ../../modules/cli.nix
    ../../modules/fonts.nix
    ../../modules/games.nix
    ../../modules/kde.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
    system76 = {
      enableAll = true;
      power-daemon.enable = false;
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  ];


  environment.systemPackages = with pkgs; [
    alacritty
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.pl
    avahi
    calibre
    chromium
    docker-compose
    ((emacsPackagesFor emacs30).emacsWithPackages (epkgs: with epkgs.melpaPackages; [
      emacsql
      vterm
    ]))
    firefox
    gcc
    graphviz-nox
    libreoffice-fresh
    libvterm-neovim
    keepassxc
    nix-direnv
    plantuml
    sbcl
    sqlite
    vlc
  ];

  networking = rec {
    hostName = "lemur";
    firewall.enable = false;
  };

  programs = {
    zsh.enable = true;
  };

  services = {
    acpid.enable = true;

    fstrim.enable = true;

    hardware.bolt.enable = true;

    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = false;
        naturalScrolling = true;
        tapping = true;
      };
    };

    openssh.enable = true;

    power-profiles-daemon.enable = true;

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

    tailscale = {
      enable = true;
      port = 56788;
    };

    xserver = {
      # Desktop manager enabled in kde.nix
      videoDrivers = [ "modesetting" ];
    };
  };

  users.users.ctr = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    home = "/home/ctr";
    extraGroups = [ "docker" "wheel" "networkmanager" "vboxusers" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = (import ../../modules/sshkeys.nix).personal;
  };

  virtualisation = {
    docker.enable = true;
    # virtualbox.host.enable = true;
  };

  system.stateVersion = "20.09"; # change with care

  time.timeZone = "America/New_York";
}

