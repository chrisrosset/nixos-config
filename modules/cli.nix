# Command line utilities that should be present on all systems.

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ag
    bat
    coreutils
    curl
    fdupes
    file
    git
    gnumake
    hdparm
    htop
    iotop
    iperf
    iperf3
    jq
    killall
    loc
    mosh
    ms-sys
    ncdu
    nmap
    ntfs3g
    parallel
    parted
    pv
    python3
    qrencode
    ripgrep
    rsync
    smartmontools
    sshfs
    strace
    tcpdump
    tmux
    tree
    unar
    unzip
    vim
    w3m
    wget
    which
    youtube-dl
  ];
}
