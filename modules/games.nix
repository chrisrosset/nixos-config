{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    brogue-ce
    crawl
    gzdoom
    nethack
    openmw
    openttd
    wesnoth
  ];
}
