{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; with pkgs.kdePackages; [
    ark
    gwenview
    kdialog
    krita
    okular
    qbittorrent
    spectacle
    trayscale
    wl-clipboard
  ];

  networking.networkmanager.enable = true;

  services = {
    desktopManager.plasma6.enable = true;

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
