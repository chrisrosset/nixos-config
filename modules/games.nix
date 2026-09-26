{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gzdoom
    nethack
    openmw
    openttd
    wesnoth
  ];
}
