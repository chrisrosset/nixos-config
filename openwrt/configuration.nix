{ lib, pkgs, ... }:

let
  sshKeys = import ../data/ssh-keys.nix;
  hosts = import ../data/hosts-166.nix;
  lan = {
    # Be very careful when changing these values.
    prefix = "10.166.0";
    domain = "lan";
  };
  ipv4 = host: "${lan.prefix}.${toString host.suffix}";
  fqdn = host: "${host.hostname}.${lan.domain}";
  mkReservation = host: {
    name = host.hostname;
    ip = ipv4 host;
    inherit (host) mac;
    dns = "1";
  };
  serviceAliases = [
    { name = "home-assistant-host"; host = hosts.ecolite; }
    { name = "mqtt-broker"; host = hosts.ecolite; }
    { name = "zigbee2mqtt-host"; host = hosts.ecolite; }
    { name = "zigbee-coordinator"; host = hosts.coordinator; }
  ];

  # Shared clock and logging policy; hostnames, compatibility, and LEDs stay local.
  systemSettings = {
    timezone = "EST5EDT,M3.2.0,M11.1.0";
    zonename = "America/New_York";
    log_size = "128";
    cronloglevel = "5";
    ttylogin = "0";
    urandom_seed = "0";
    log_proto = "udp";
    conloglevel = "8";
  };

  ntpServers = [
    "0.openwrt.pool.ntp.org"
    "1.openwrt.pool.ntp.org"
    "2.openwrt.pool.ntp.org"
    "3.openwrt.pool.ntp.org"
  ];

  # Configuration-only adoption: do not refresh feeds or reconcile packages.
  # These are internal Dewclaw options, so default.nix pins its revision.
  configurationOnlySteps = {
    distfeeds.apply = lib.mkForce ":";
    packages = {
      prepare = lib.mkForce "";
      copy = lib.mkForce "";
      apply = lib.mkForce ":";
    };
  };

  # Keep firmware upgrades manual; rebuild images with installed packages.
  # Automatic search is only a UI check, not automatic installation.
  attendedSysupgrade = {
    server.server.url = "https://sysupgrade.openwrt.org";
    client.client = {
      upgrade_packages = "1";
      # Explicitly decline Status/Overview checks to suppress the prompt.
      login_check_for_upgrades = "0";
      auto_search = "0";
      advanced_mode = "0";
    };
    owut.owut = { };
  };

  sharedManagement = {
    assertions = [
      {
        assertion = builtins.all (
          host: builtins.isInt host.suffix && host.suffix >= 1 && host.suffix <= 254
        ) (builtins.attrValues hosts);
        message = "Site 166 host suffixes must be integers from 1 to 254.";
      }
      {
        assertion =
          let
            names = map (host: host.hostname) (builtins.attrValues hosts);
            suffixes = map (host: host.suffix) (builtins.attrValues hosts);
          in
          builtins.length (lib.unique names) == builtins.length names
          && builtins.length (lib.unique suffixes) == builtins.length suffixes;
        message = "Site 166 hostnames and IPv4 suffixes must be unique.";
      }
    ];

    # Replaces the entire file: include every required public key here.
    etc."dropbear/authorized_keys".text =
      lib.concatStringsSep "\n" [
        sshKeys.ctr.lemur
        sshKeys.ctr.ecolite
      ] + "\n";

    # All devices share this password; SSH password-login policy stays per-device.
    # Generate locally with `openssl passwd -6`; encrypt the complete $6$ hash.
    users.root.hashedPasswordSecret = "root_password_hash";

    # Decrypt the shared secrets file only at deployment time; Wi-Fi is AP-only.
    # The deploying user needs the SOPS key; plaintext must not enter Git/store.
    # Validate the hash before any device changes, rather than pass null to Dewclaw.
    secretsCommand = lib.getExe (
      pkgs.writeShellApplication {
        name = "openwrt-ap-secrets";
        runtimeInputs = [ pkgs.sops pkgs.jq ];
        text = ''
          : "''${DEWCLAW_SECRETS_FILE:?Set DEWCLAW_SECRETS_FILE to the encrypted SOPS file}"
          secrets=$(sops --decrypt --output-type json "$DEWCLAW_SECRETS_FILE")
          if ! printf '%s' "$secrets" | jq --exit-status '
            .root_password_hash |
            if type == "string" then
              test("^\\$6\\$(rounds=[0-9]+\\$)?[./A-Za-z0-9]{1,16}\\$[./A-Za-z0-9]{86}$")
            else
              false
            end
          ' >/dev/null; then
            echo "root_password_hash must contain a SHA-512 crypt password hash" >&2
            exit 1
          fi
          printf '%s\n' "$secrets"
        '';
      }
    );
  };

  accessPoints = import ./access-points.nix {
    inherit
      lib
      hosts
      ipv4
      sharedManagement
      configurationOnlySteps
      attendedSysupgrade
      systemSettings
      ntpServers
      ;
  };
in
{
  openwrt = accessPoints // {
    router = sharedManagement // {
      deploy = {
        host = ipv4 hosts.router;
        user = "root";
        rebootAllowance = 120;
        rollbackTimeout = 120;
      };
      deploySteps = configurationOnlySteps;

      # Share the AP management credentials while preserving service boot state.
      # The shared root password also controls LuCI through retained rpcd settings.
      # Retain UI, wake-on-LAN, and hardware defaults; declared UCI files replace
      # their entire contents, and undeclared/unretained UCI files are deleted.
      uci.retain = [
        "etherwake"
        "luci"
        "rpcd"
        "ubihealthd"
        "ubootenv"
        "ucitrack"
        "uhttpd"
      ];

      uci.settings = {
        attendedsysupgrade = attendedSysupgrade;

        network = {
          interface = {
            loopback = {
              device = "lo";
              proto = "static";
              ipaddr = "127.0.0.1";
              netmask = "255.0.0.0";
            };
            lan = {
              device = "br-lan";
              proto = "static";
              netmask = "255.255.255.0";
              ip6assign = "60";
              ipaddr = ipv4 hosts.router;
            };
            wan = {
              proto = "dhcp";
              device = "wan";
              peerdns = "0";
              dns = [ "1.1.1.1" "8.8.8.8" ];
            };
            wan6 = {
              proto = "dhcpv6";
              device = "wan";
              reqaddress = "try";
              reqprefix = "auto";
              peerdns = "0";
              dns = [ "2606:4700:4700::1111" ];
            };
          };
          globals.globals = {
            ula_prefix = "fdb9:c400:c979::/48";
            # Preserve the DHCPv6 client identity generated during upgrade.
            dhcp_default_duid = "0004e55b3651c66f4ea3bf58b70b9eac74ba";
          };
          device = [
            {
              name = "br-lan";
              type = "bridge";
              ports = [ "lan1" "lan2" "lan3" "lan4" ];
            }
            {
              name = "wan";
              # Preserve the existing ISP-facing identity.
              macaddr = "5a:ef:68:0f:24:6c";
              ipv6 = "1";
            }
          ];
        };

        # Preserve the current routed LAN/WAN policy, including stock IPsec rules.
        firewall = {
          defaults = [
            {
              syn_flood = "1";
              input = "ACCEPT";
              output = "ACCEPT";
              forward = "REJECT";
            }
          ];
          zone = [
            {
              name = "lan";
              input = "ACCEPT";
              output = "ACCEPT";
              forward = "ACCEPT";
              network = [ "lan" ];
            }
            {
              name = "wan";
              input = "REJECT";
              output = "ACCEPT";
              forward = "REJECT";
              masq = "1";
              mtu_fix = "1";
              network = [ "wan" "wan6" ];
            }
          ];
          forwarding = [
            {
              src = "lan";
              dest = "wan";
            }
          ];
          rule = [
            {
              name = "Allow-DHCP-Renew";
              src = "wan";
              proto = "udp";
              dest_port = "68";
              target = "ACCEPT";
              family = "ipv4";
            }
            {
              name = "Allow-Ping";
              src = "wan";
              proto = "icmp";
              icmp_type = "echo-request";
              family = "ipv4";
              target = "ACCEPT";
            }
            {
              name = "Allow-IGMP";
              src = "wan";
              proto = "igmp";
              family = "ipv4";
              target = "ACCEPT";
            }
            {
              name = "Allow-DHCPv6";
              src = "wan";
              proto = "udp";
              src_ip = "fc00::/6";
              dest_ip = "fc00::/6";
              dest_port = "546";
              family = "ipv6";
              target = "ACCEPT";
            }
            {
              name = "Allow-MLD";
              src = "wan";
              proto = "icmp";
              src_ip = "fe80::/10";
              icmp_type = [ "130/0" "131/0" "132/0" "143/0" ];
              family = "ipv6";
              target = "ACCEPT";
            }
            {
              name = "Allow-ICMPv6-Input";
              src = "wan";
              proto = "icmp";
              icmp_type = [
                "echo-request"
                "echo-reply"
                "destination-unreachable"
                "packet-too-big"
                "time-exceeded"
                "bad-header"
                "unknown-header-type"
                "router-solicitation"
                "neighbour-solicitation"
                "router-advertisement"
                "neighbour-advertisement"
              ];
              limit = "1000/sec";
              family = "ipv6";
              target = "ACCEPT";
            }
            {
              name = "Allow-ICMPv6-Forward";
              src = "wan";
              dest = "*";
              proto = "icmp";
              icmp_type = [
                "echo-request"
                "echo-reply"
                "destination-unreachable"
                "packet-too-big"
                "time-exceeded"
                "bad-header"
                "unknown-header-type"
              ];
              limit = "1000/sec";
              family = "ipv6";
              target = "ACCEPT";
            }
            {
              name = "Allow-IPSec-ESP";
              src = "wan";
              dest = "lan";
              proto = "esp";
              target = "ACCEPT";
            }
            {
              name = "Allow-ISAKMP";
              src = "wan";
              dest = "lan";
              dest_port = "500";
              proto = "udp";
              target = "ACCEPT";
            }
          ];
        };

        # Unlike the APs, the router serves DHCPv4, DHCPv6, RA, and local DNS.
        dhcp = {
          dnsmasq = [
            {
              domainneeded = "1";
              localise_queries = "1";
              rebind_protection = "1";
              rebind_localhost = "1";
              local = "/${lan.domain}/";
              domain = lan.domain;
              expandhosts = "1";
              authoritative = "1";
              readethers = "1";
              leasefile = "/tmp/dhcp.leases";
              resolvfile = "/tmp/resolv.conf.d/resolv.conf.auto";
              localservice = "1";
              ednspacket_max = "1232";
              address = [
                "/*.home.rosset.pl/${ipv4 hosts.ecolite}"
                "/use-application-dns.net/"
              ];
            }
          ];
          dhcp.lan = {
            interface = "lan";
            start = "100";
            limit = "150";
            leasetime = "12h";
            dhcpv4 = "server";
            dhcpv6 = "server";
            ra = "server";
            ra_slaac = "1";
            ra_flags = [ "managed-config" "other-config" ];
          };
          odhcpd.odhcpd = {
            maindhcp = "0";
            leasefile = "/tmp/odhcpd.leases";
            leasetrigger = "/usr/sbin/odhcpd-update";
            loglevel = "4";
            hostsdir = "/tmp/hosts";
            piodir = "/tmp/odhcpd-piodir";
          };
          host = map mkReservation [
            hosts.morgoth
            hosts.ecolite
            hosts.apA
            hosts.apB
            hosts.coordinator
            hosts.bravia
            hosts.denon
            hosts.camera
          ];
          # Service aliases follow the named reservations' IPv4/IPv6 records.
          cname = map (alias: {
            cname = "${alias.name}.${lan.domain}";
            target = fqdn alias.host;
          }) serviceAliases;
        };

        system = {
          system = [
            (systemSettings // {
              hostname = hosts.router.hostname;
              compat_version = "1.1";
            })
          ];
          timeserver.ntp = {
            server = ntpServers;
            # Preserve the router's local NTP-server role; APs are clients only.
            enable_server = "1";
          };
          led = {
            led_wan = {
              name = "WAN";
              sysfs = "pca963x:caiman:white:wan";
              trigger = "netdev";
              mode = "link tx rx";
              dev = "wan";
            };
            led_usb1 = {
              name = "USB 1";
              sysfs = "pca963x:caiman:white:usb2";
              trigger = "usbport";
              port = [ "usb1-port1" ];
            };
            led_usb2 = {
              name = "USB 2";
              sysfs = "pca963x:caiman:white:usb3_1";
              trigger = "usbport";
              port = [ "usb2-port1" "usb3-port1" ];
            };
            led_usb2_ss = {
              name = "USB 2 SS";
              sysfs = "pca963x:caiman:white:usb3_2";
              trigger = "usbport";
              port = [ "usb3-port1" ];
            };
          };
        };

        # Preserve key-only SSH authentication, distinct from the AP policy.
        dropbear.dropbear = [
          {
            PasswordAuth = "off";
            Port = "22";
            RootPasswordAuth = "off";
          }
        ];

        # Keep only disabled radio identities; discard historical SSIDs and keys.
        wireless.wifi-device = {
          radio0 = {
            type = "mac80211";
            path = "soc/soc:pcie/pci0000:00/0000:00:01.0/0000:01:00.0";
            disabled = "1";
          };
          radio1 = {
            type = "mac80211";
            path = "soc/soc:pcie/pci0000:00/0000:00:02.0/0000:02:00.0";
            disabled = "1";
          };
        };
      };
    };
  };
}
