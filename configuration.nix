# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # packages
  environment.systemPackages = with pkgs; [
      git
      hdparm
      htop
      pv
      screen
      tmux
      vim
      wget
      zsh
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "prometheus";
  networking.hostId   = "428dc8b7";
  networking.firewall.enable    = false;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 445 139 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];

  fileSystems = [
    # Hard Drives
    {
      mountPoint = "/mnt/bay1";
      device = "/dev/disk/by-uuid/cb90ee6f-e901-4751-81b4-38f01c8da4d6";
      fsType = "ext4";
    }
    {
      mountPoint = "/mnt/bay2";
      device = "/dev/disk/by-uuid/80c8651d-866f-4eec-8cd1-6e965ef3fd81";
      fsType = "ext4";
    }

    # Network binds
    {
      mountPoint = "/exports/movies";
      device = "/mnt/bay1/movies";
      options = "bind";
    }
  
    {
      mountPoint = "/exports/photos";
      device = "/mnt/bay2/photos";
      options = "bind";
    }
  
    {
      mountPoint = "/exports/random";
      device = "/mnt/bay2/random";
      options = "bind";
    }
  
    {
      mountPoint = "/exports/series";
      device = "/mnt/bay1/series";
      options = "bind";
    }
  ];

  #users.mutableUsers = false;
  users.extraUsers.ctr = {
    isNormalUser = true;
    uid = 1000;
    shell = "${pkgs.zsh}/bin/zsh";
  };


  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # List services that you want to enable:

  services.avahi.enable   = true;
  services.avahi.nssmdns  = true;

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  services.ntp.enable     = true;
  time.timeZone = "Europe/London";

  services.samba.enable   = true;
  services.samba.nsswins  = true;
  services.samba.extraConfig = ''
    workgroup = WORKGROUP
    server string = Home server
    security = user
    map to guest = Bad User
    guest account = nobody

    [movies]
      path = /exports/movies
      public = yes
      only guest = yes
      writable = yes
  
    [photos]
      path = /exports/photos
      public = yes
      only guest = yes
      writable = yes

    [random]
      path = /exports/random
      public = yes
      only guest = yes
      writable = yes

    [series]
      path = /exports/series
      public = yes
      only guest = yes
      writable = yes
  '';

}
