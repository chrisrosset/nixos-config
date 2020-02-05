# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  keepassWithPlugins = pkgs.keepass.override {
    plugins = [ pkgs.keepass-keepasshttp ];
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./morgoth/hardware-configuration.nix
      ./modules/fonts.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sdb";
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    alacritty
    ag
    calibre
    coreutils
    digikam
    docker
    emacs
    fcron
    feh
    file
    firefox
    gcc
    gimp
    git
    gnumake
    gparted
    htop
    iotop
    keepassWithPlugins
    ledger
    ledger-web
    mosquitto
    okular
    p7zip
    pkgconfig
    python
    python3
    tmux
    transmission_gtk
    tree
    sakura
    st
    syncthing
    which
    wget
    unzip
    vim
    vlc
    zlib
    zsh

    ntfs3g
    parted
    ms-sys

    #cura

    # development packages
    libxml2
    libxslt
    xorg.libX11
  ];

  hardware.pulseaudio.enable = true;

  nixpkgs.config = {
    allowUnfree = false;
  };

  networking.firewall.enable = false;
  networking.hostName = "morgoth"; # Define your hostname.
  networking.wireless.enable = false;

  # List services that you want to enable:
  services.cron = {
    enable = true;
    systemCronJobs = [
      # Remaps Japanese unused modifier keys to L/R Ctrl and Caps Lock to Backspace
      "@reboot root setkeycodes 0x7b 29 0x79 97 0x3a 14"
    ];
  };

  services.fcron = { enable = true; };

  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    systemService = true;
    user = "ctr";
    group = "users";
    dataDir = "/home/ctr/Sync";

    # New in 19.03
    # configDir = "/home/ctr/.config/syncthing";
  };

  services.xserver = {
    enable = true;
    layout = "us";

    desktopManager = {
      default = "xfce";
      plasma5.enable = false;
      xfce.enable = true;
      xterm.enable = false;
    };
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";

  time.timeZone = "America/New_York";

  #users.mutableUsers = false;
  users.extraUsers.ctr = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "docker" "dialout" ];
    createHome = true;
    home = "/home/ctr";
    uid = 1000;
    shell = pkgs.zsh;
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;
}
