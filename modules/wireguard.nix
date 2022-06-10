let
  lib = import <nixpkgs/lib>;
  names = {
    "prometheus" = "192.168.200.10";
    "DESKTOP-TDVT7N5" = "192.168.200.11";
    "galaxy-a71" = "192.168.200.12";
    "lemur" = "192.168.200.13";
    "morgoth" = "192.168.200.20";
    "kraken" = "192.168.200.50";
    "sister-asus" = "192.168.200.80";
  };

  port = 51820;

  server = {
    publicKey = "kHXlDYyKU8t/JQX3NpTxaSp+udYr67jzTN19MPgOk1s=";
    allowedIPs = [ "192.168.200.0/24" ];
    endpoint = "rosset.tech:${toString port}";
    persistentKeepalive = 20;
  };

  peers = lib.mapAttrsToList (name: ip: { "name" = name; "ip" = ip; }) names;
in
{
  getConfig = (hostname: {
    ips = [ "${builtins.getAttr hostname names}/32" ];
    privateKeyFile = "/root/${hostname}.key";
    peers = [ server ];
  });

  serverPort = port;

  getServerPeers = (keypath:
    lib.mapAttrsToList
      (name: ip: {
        publicKey = (lib.removeSuffix "\n" (builtins.readFile "${keypath}/${name}.pub"));
        allowedIPs = [ "${ip}/32"];
      }) names
  );

  extraHosts = lib.concatStrings (lib.mapAttrsToList (name: ip: "${ip} ${name}.vpn.rosset.tech \n") names);
}
