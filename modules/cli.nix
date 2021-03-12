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
    hdparm
    htop
    iotop
    iperf
    iperf3
    mosh
    ms-sys
    ncdu
    nmap
    ntfs3g
    parted
    pv
    python3
    ripgrep
    rsync
    sshfs
    tcpdump
    tmux
    tree
    unzip
    vim
    w3m
    wget
    which
  ];
}
