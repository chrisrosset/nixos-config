# This data is used to create the DHCP static leases.
# Suffix is the final octet of the IPv4 address.
{
  router = {
    hostname = "router";
    suffix = 1;
  };
  morgoth = {
    hostname = "morgoth";
    suffix = 4;
    mac = "D0:50:99:51:30:68";
  };
  ecolite = {
    hostname = "ecolite";
    suffix = 5;
    mac = "84:47:09:A2:1A:01";
  };
  apA = {
    hostname = "gl-b3000-a";
    suffix = 8;
    mac = "94:83:C4:A4:D9:F4";
  };
  apB = {
    hostname = "gl-b3000-b";
    suffix = 9;
    mac = "94:83:C4:A4:DB:2A";
  };
  coordinator = {
    hostname = "SLZB-MR4";
    suffix = 11;
    mac = "00:4B:12:96:1B:3B";
  };
  bravia = {
    hostname = "bravia";
    suffix = 62;
    mac = "94:DB:56:0A:D9:B4";
  };
  denon = {
    hostname = "denon";
    suffix = 64;
    mac = "00:05:CD:A1:91:BD";
  };
  camera = {
    hostname = "amc04759-ffa3ef";
    suffix = 75;
    mac = "9C:8E:CD:24:53:DA";
  };
}
