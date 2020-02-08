{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ark
    gwenview
  ];

  hardware.pulseaudio.enable = true;

  networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;

    desktopManager = {
      plasma5.enable = true;
    };
  };
}
