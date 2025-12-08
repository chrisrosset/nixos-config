{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; with pkgs.kdePackages; [
    ark
    gwenview
    kdialog
    krita
    okular
    qbittorrent
    simplescreenrecorder
    spectacle
    trayscale
    xclip
  ];

  networking.networkmanager.enable = true;

  services = {
    desktopManager.plasma6.enable = true;

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    xserver.enable = true;
  };
}
