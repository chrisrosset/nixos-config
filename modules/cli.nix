# Command line utilities that should be present on all systems.

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ag
    coreutils
    curl
    file
    git
    gnumake
    htop
    iotop
    ncdu
    nmap
    pv
    python3
    ripgrep
    rsync
    sshfs
    tmux
    tree
    unzip
    vim
    which
    wget
  ];
}
