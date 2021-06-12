{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; with pkgs.plasma5Packages.kdeApplications; [
    ark
    gwenview
    kdialog
    krita
    okular
    qbittorrent
    spectacle
    xclip
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
