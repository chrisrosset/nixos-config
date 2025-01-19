{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; with pkgs.plasma5Packages.kdeApplications; [
    ark
    gwenview
    kdialog
    krita
    okular
    qbittorrent
    simplescreenrecorder
    spectacle
    xclip
  ];

  networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;

    desktopManager = {
      plasma5.enable = true;
    };
  };
}
