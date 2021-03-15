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
  imports = [
      ./hardware/filco-jp.nix
      ./hardware/morgoth.nix
      ./modules/cli.nix
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
    calibre
    digikam
    docker
    emacs
    feh
    firefox
    gcc
    gimp
    gparted
    keepassWithPlugins
    ledger
    ledger-web
    mosquitto
    okular
    p7zip
    pkgconfig
    python
    python3
    transmission_gtk
    syncthing
    vlc
    zlib
    zsh

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
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;
}
