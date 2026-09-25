{ config, pkgs, ... }:
let
  # syncthingCfg = import ../../modules/syncthing.nix;
  transmissionPath = "/srv/raid/export/transmission";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/cli.nix
      ../../modules/nix.nix
      ../../modules/ssh.nix
      ../../modules/zabbix.nix
    ];

  environment.systemPackages = with pkgs; [
      cron
      fish
      samba
      zsh
  ];

  networking = rec {
    firewall.enable = false;
    hostName = "tiamat";
  };

  programs.fish.enable = true;

  security.sudo.enable = true;

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
        domain = true;
      };
    };

    cron.enable = true;

    ntp.enable = true;

    samba = {
      enable   = false;
      nsswins  = true;
      settings = ''
workgroup = WORKGROUP
server string = Home server
security = user
map to guest = Bad User
guest account = ctr

[export]
  path = /srv/raid/export
  public = yes
  only guest = yes
  writable = yes
'';
    };

    tailscale.enable = true;

    transmission = {
      enable = true;

      settings = {
        download-dir = "${transmissionPath}/downloads";
        incomplete-dir = "${transmissionPath}/incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
        watch-dir = "${transmissionPath}/watch";
        watch-dir-enabled = true;

      };
    };
  };

  time.timeZone = "UTC";

  users.extraUsers = {
    ctr = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" "nogroup" "transmission" ];
      uid = 1000;
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = (import ../../data/ssh-keys.nix).personal;
    };

    hass.isNormalUser = true;
  };

  system.stateVersion = "22.11";
}
