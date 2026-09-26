{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/filco-jp.nix
    ../../modules/games.nix
    ../../modules/kde.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    bluetooth.enable = true;
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
    calibre
    chromium
    ((emacsPackagesFor emacs).emacsWithPackages (epkgs: with epkgs.melpaPackages; [
      emacsql
      vterm
    ]))
    firefox
    gcc
    ghostty
    graphviz-nox
    libreoffice
    libvterm-neovim
    keepassxc
    nix-direnv
    plantuml
    sbcl
    sqlite
    vlc
    yt-dlp
  ];

  networking = {
    hostName = "lemur";
    firewall.enable = false;
  };

  programs = {
    zsh.enable = true;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
    };

    fstrim.enable = true;

    hardware.bolt.enable = true;

    power-profiles-daemon.enable = true;

    syncthing = {
      enable = true;
    };

  };

  users.users.ctr.shell = pkgs.zsh;

  virtualisation = {
    docker.enable = true;
  };

  system.stateVersion = "20.09";

  time.timeZone = "America/New_York";
}

