{
  host = (import ./hosts-166.nix).ecolite;
  ports = {
    http = 9428;
    syslog = 1514;
  };
}
