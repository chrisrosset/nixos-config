{ config, lib, ... }:
let
  logging = import ../../data/logging.nix;
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
        address = "0.0.0.0:${toString logging.ports.syslog}";
      });
      transforms.normalize_syslog = {
        type = "remap";
        inputs = [ "syslog_tcp" "syslog_udp" ];
        source = ''
          # Match journal uploads for unified hostname queries and stream labels.
          ._HOSTNAME = del(.hostname)
          if ._HOSTNAME == null || ._HOSTNAME == "" || ._HOSTNAME == "-" {
            ._HOSTNAME = .source_ip
          }
          del(.host)

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
        uri = "http://127.0.0.1:${toString logging.ports.http}/insert/jsonline"
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
