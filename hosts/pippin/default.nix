{ lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/base.nix
  ];

  roles.server = true;

  networking = {
    hostName = "pippin";
    firewall.enable = true;
  };

  # The ctr account uses SSH keys and has no password.
  security.sudo.wheelNeedsPassword = false;

  image.baseName = "nixos-pippin";

  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "26.05";
}
