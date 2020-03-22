{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.bluetooth.enable = true;

  # packages
  environment.systemPackages = with pkgs; [
      cron
      docker
      git
      gnumake
      fortune
      hdparm
      htop
      ncdu
      pv
      samba
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

  fileSystems = [
    # RAID Array
    {
      mountPoint = "/mnt/raid";
      label = "data";
      fsType = "ext4";
    }

    # Network binds
    {
      mountPoint = "/exports/movies";
      device = "/mnt/raid/movies";
      options = [ "bind" ];
    }

    {
      mountPoint = "/exports/photos";
      device = "/mnt/raid/photos";
      options = [ "bind" ];
    }

    {
      mountPoint = "/exports/random";
      device = "/mnt/raid/random";
      options = [ "bind" ];
    }

    {
      mountPoint = "/exports/series";
      device = "/mnt/raid/series";
      options = [ "bind" ];
    }
  ];

  security.sudo.enable = true;

  users.extraUsers = {
    ctr = {
      isNormalUser = true;
      uid = 1000;
      shell = "${pkgs.zsh}/bin/zsh";
      extraGroups = [ "wheel" "nogroup" ];
    };
  };


  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # List services that you want to enable:

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      domain = true;
    };
  };

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  services.ntp.enable     = true;
  time.timeZone = "UTC";

  services.cron = {
      enable = true;
  };

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

  virtualisation.docker.enable = true;
}
