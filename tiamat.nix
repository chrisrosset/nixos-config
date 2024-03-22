{ config, pkgs, ... }:
let
  # syncthingCfg = import ./modules/syncthing.nix;
  wireguardCfg = import ./modules/wireguard.nix;
  transmissionPath = "/srv/raid/export/transmission";
in
{
  imports =
    [
      ./hardware/tiamat.nix
      ./modules/cli.nix
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
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

  programs.fish.enable = true;

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
      settings.PermitRootLogin = "no";
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
      openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
    };

    hass.isNormalUser = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
