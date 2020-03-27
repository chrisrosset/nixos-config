# Command line utilities that should be present on all systems.

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ag
    curl
    git
    file
    htop
    ncdu
    pv
    ripgrep
    rsync
    sshfs
    tmux
    tree
    vim
    wget
    unzip
  ];
}
