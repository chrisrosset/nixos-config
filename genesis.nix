{ config, pkgs, ... }:
let
  mySshKeys = import ./modules/sshkeys.nix;
in
{
  imports = [
      ./genesis/hardware-configuration.nix
      ./genesis/networking.nix # generated at runtime by nixos-infect
      ./modules/cli.nix
    ];

  boot.cleanTmpDir = true;

  environment.systemPackages = with pkgs; [];

  networking.hostName = "genesis";

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
    };
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "19.09";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ctr = {
    isNormalUser = true;
    group = "users";
    uid = 1000;
    home = "/home/ctr";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = with mySshKeys; [ ctr.morgoth ctr.motile ];
  };

  time.timeZone = "UTC";
}
