{ config, pkgs, ... }:
let
  wireguardCfg = import ./modules/wireguard.nix;
in
{
  imports = [
      ./genesis/hardware-configuration.nix
      ./genesis/networking.nix # generated at runtime by nixos-infect
      ./modules/cli.nix
    ];

  boot.cleanTmpDir = true;
  boot.kernelPackages = pkgs.linuxPackages_5_6;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  environment.systemPackages = with pkgs; [];

  networking.hostName = "genesis";
  networking.firewall = {
    enable = false;
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 wireguardCfg.serverPort ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "192.168.200.1/24" ];
      listenPort = wireguardCfg.serverPort;
      privateKeyFile = "/root/wireguard/genesis.key";

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
      '';

      peers = wireguardCfg.getServerPeers "/root/wireguard";
    };
  };

  services = {
    fail2ban = {
      enable = true;
    };

    openssh = {
      enable = true;
      permitRootLogin = "no";
    };
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "19.09";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ctr = {
    isNormalUser = true;
    group = "users";
    uid = 1000;
    home = "/home/ctr";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = (import ./modules/sshkeys.nix).personal;
  };

  time.timeZone = "UTC";
}
