# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./genesis/hardware-configuration.nix
      ./genesis/nixos-in-place.nix
      ./modules/cli.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  networking.hostName = "genesis";

  time.timeZone = "UTC";

  environment.systemPackages = with pkgs; [
  ];

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.ctr = {
    isNormalUser = true;
    group = "users";
    uid = 1000;
    home = "/home/ctr";
    extraGroups = [ "wheel" ];
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "16.09";

}
