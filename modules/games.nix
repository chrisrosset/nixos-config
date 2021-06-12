{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    brogue
    crawl
    gzdoom
    nethack
    openmw
    openttd
    wesnoth
  ];
}
