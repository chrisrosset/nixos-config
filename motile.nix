# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./motile/hardware-configuration.nix
      ./modules/cli.nix
      ./modules/fonts.nix
      ./modules/kde.nix
    ];

  boot = {
    loader = {
      grub = {
        device = "/dev/nvme0n1";
        enable = true;
        version = 2;
      };
      timeout = 15;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  environment.systemPackages = with pkgs; [
    alacritty
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    calibre
    chromium
    crawl
    emacs
    firefox
    git
    gnumake
    graphviz
    gzdoom
    keepassxc
    ledger
    nethack
    ntfs3g
    vlc
    zsh
  ];

  networking.hostName = "motile";
  networking.useDHCP = false;
  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;
  networking.firewall.enable = false;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  services.acpid.enable = true;
  services.tlp.enable = true;
  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "ctr";
    dataDir = "/home/ctr/syncthing/";
    configDir = "/home/ctr/.config/syncthing";

  };

  services.udev.packages = [ pkgs.yubikey-personalization ];

  services.xserver = {
    layout = "us";

    # touchpad support
    libinput = {
      enable = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  #users.mutableUsers = false;
  users.users.ctr = {
    isNormalUser = true;
    group = "users";
    uid = 1000;
    home = "/home/ctr";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

  time.timeZone = "America/New_York";

}

