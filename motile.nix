# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./motile/hardware-configuration.nix
      ./modules/fonts.nix
      ./modules/kde.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/nvme0n1";
  };

  networking.hostName = "motile";
  networking.useDHCP = false;
  networking.interfaces.enp2s0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;
  networking.firewall.enable = false;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    ag
    alacritty
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    crawl
    curl
    emacs
    file
    firefox
    git
    gnumake
    htop
    keepassxc
    ledger
    ncdu
    nethack
    pv
    ripgrep
    tmux
    tree
    vim
    vlc
    wget
    zsh
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  services.tlp.enable = true;
  services.acpid.enable = true;
  services.openssh.enable = true;

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
}

