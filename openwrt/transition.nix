{ lib, pkgs, ... }:

let
  final = import ./configuration.nix { inherit lib pkgs; };
  router = final.openwrt.router;
  oldAddress = "192.168.0.1";
in
{
  # Build only the router: APs acquire their new reserved addresses through DHCP.
  openwrt.router = lib.recursiveUpdate router {
    # Connect and confirm through the retained address across the reboot.
    deploy.host = oldAddress;
    uci.settings = {
      # The primary LAN and its DHCP pool use the final subnet. This separate
      # interface provides old-subnet access without creating a second DHCP pool.
      network.interface.lan_old = {
        device = "br-lan";
        proto = "static";
        ipaddr = oldAddress;
        netmask = "255.255.255.0";
      };
      dhcp.dhcp.lan_old = {
        interface = "lan_old";
        ignore = "1";
        ra = "disabled";
        dhcpv6 = "disabled";
        ndp = "disabled";
      };
      firewall.zone = map (
        zone:
        if zone.name == "lan" then
          zone // { network = zone.network ++ [ "lan_old" ]; }
        else
          zone
      ) router.uci.settings.firewall.zone;
    };
  };
}
