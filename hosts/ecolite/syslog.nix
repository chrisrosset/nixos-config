{ config, lib, ... }:
let
  hosts = import ../../data/hosts-166.nix;
  hostnames = builtins.listToAttrs (map (host: {
    name = "10.166.0.${toString host.suffix}";
    value = host.hostname;
  }) (builtins.attrValues hosts));
in
{
  services.vector = {
    enable = true;
    settings = {
      data_dir = "/var/lib/vector";
      timezone = config.time.timeZone;
      sources = lib.genAttrs [ "syslog_tcp" "syslog_udp" ] (name: {
        type = "syslog";
        mode = if name == "syslog_tcp" then "tcp" else "udp";
        address = "0.0.0.0:1514";
      });
      transforms.normalize_syslog = {
        type = "remap";
        inputs = [ "syslog_tcp" "syslog_udp" ];
        source = ''
          inventory = ${builtins.toJSON hostnames}
          .reported_hostname = .hostname
          if !exists(.hostname) || .hostname == "" || .hostname == "-" || .hostname == .source_ip {
            name = get(inventory, [string!(.source_ip)]) ?? null
            if name != null {
              .hostname = name
            } else {
              .hostname = .source_ip
            }
          }
          .host = .hostname
          ._HOSTNAME = .hostname
          .level = .severity
          if .level == "crit" {
            .level = "critical"
          } else if .level == "err" {
            .level = "error"
          }
        '';
      };
      sinks.victorialogs_syslog = {
        type = "http";
        inputs = [ "normalize_syslog" ];
        uri = "http://127.0.0.1:9428/insert/jsonline"
          + "?_msg_field=message&_time_field=timestamp"
          + "&_stream_fields=_HOSTNAME,appname";
        encoding.codec = "json";
        framing.method = "newline_delimited";
        compression = "gzip";
        healthcheck.enabled = false;
        batch.timeout_secs = 1;
        buffer = {
          type = "disk";
          max_size = 536870912;
          when_full = "block";
        };
      };
    };
  };

  systemd.services.vector = {
    wants = [ "victorialogs.service" ];
    after = [ "victorialogs.service" ];
  };
}
