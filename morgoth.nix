{ config, pkgs, ... }:
let
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports = [
      ./hardware/morgoth.nix
      ./modules/cli.nix
    ];

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    mosquitto
    p7zip
    syncthing
    zsh
  ];

  hardware.pulseaudio.enable = true;

  nixpkgs.config = {
    allowUnfree = false;
  };

  networking = rec {
    firewall.enable = false;
    hostName = "morgoth";
    extraHosts = wireguardCfg.extraHosts;
    wireguard.interfaces = {wg0 = wireguardCfg.getConfig hostName;};
  };

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

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "21.11";

  time.timeZone = "America/New_York";

  #users.mutableUsers = false;
  users.extraUsers.ctr = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "docker" "dialout" ];
    createHome = true;
    home = "/home/ctr";
    uid = 1000;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;
}
