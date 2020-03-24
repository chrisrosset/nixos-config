{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; with pkgs.kdeApplications; [
    ark
    gwenview
    kdialog
    krita
    okular
    qbittorrent
    spectacle
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
