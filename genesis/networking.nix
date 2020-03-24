{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
    defaultGateway = "172.16.254.254";
    defaultGateway6 = "";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="172.16.9.189"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="fe80::f816:3eff:fe2b:279"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "172.16.254.254"; prefixLength = 32; } ];
        ipv6.routes = [ { address = ""; prefixLength = 32; } ];
      };

    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="fa:16:3e:2b:02:79", NAME="eth0"

  '';
}
