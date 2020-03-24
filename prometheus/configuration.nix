{ config, pkgs, ... }:

let
  mySshKeys = import ../modules/sshkeys.nix;
in
{
  imports =
    [
      ../modules/cli.nix
      ./hardware-configuration.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  environment.systemPackages = with pkgs; [
      cron
      docker
      gnumake
      fortune
      hdparm
      samba
      zsh
  ];

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

  hardware.bluetooth.enable = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  networking.hostName = "prometheus";
  networking.hostId = "428dc8b7";
  networking.firewall.enable = false;

  security.sudo.enable = true;

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
        domain = true;
      };
    };

    cron.enable = true;

    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    ntp.enable = true;

    samba = {
      enable   = true;
      nsswins  = true;
      extraConfig = ''
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
    };
  };

  time.timeZone = "UTC";

  users.extraUsers = {
    ctr = {
      isNormalUser = true;
      uid = 1000;
      shell = "${pkgs.zsh}/bin/zsh";
      extraGroups = [ "wheel" "nogroup" ];
      openssh.authorizedKeys.keys = with mySshKeys; [ ctr.morgoth ctr.motile ];
    };

    hass.isNormalUser = true;
  };
  virtualisation.docker.enable = true;
}
