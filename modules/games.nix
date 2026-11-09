{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gzdoom
    luanti
    nethack
    openmw
    openttd
    wesnoth
  ];
}
