{ lib, pkgs, ... }:

let
  sshKeys = import ../data/ssh-keys.nix;

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

  wifiInterface = radio: {
    device = radio;
    network = "lan";
    mode = "ap";
    ssid = "LAN-of-the-Free";
    encryption = "psk2";
    key._secret = "wifi_password";
    ieee80211r = "1";
    # Shared across both bands and APs; matches the previously derived domain.
    mobility_domain = "ec19";
    ft_over_ds = "0";
    ft_psk_generate_local = "1";
  };

  mkAp =
    {
      hostname,
      address,
      bridgeMac,
      ulaPrefix,
      dhcpDuid,
      channel2g,
      channel5g,
    }:
    sharedManagement // {
      # Run on a host whose SSH keys are trusted by the APs.
      # Use reserved IPs and verify AP host keys under their hostnames.
      # Deploy one AP at a time; SSH confirmation does not test client connectivity.
      deploy = {
        host = address;
        user = "root";
        sshConfig.HostKeyAlias = hostname;
        rebootAllowance = 120;
        rollbackTimeout = 120;
      };

      deploySteps = configurationOnlySteps // {
        disableDnsmasq = {
          # Stop after UCI is applied so the resolver uses DHCP-supplied DNS.
          # Keep the package installed; verify DNS again after reboot/upgrades.
          priority = 100;
          apply = ''
            /etc/init.d/dnsmasq disable
            /etc/init.d/dnsmasq stop
          '';
        };
        enableLuci = {
          # Requires LuCI in the firmware: package installation is disabled above.
          # Preserve retained HTTP/HTTPS listeners and root-based web authentication.
          priority = 110;
          apply = ''
            for service in rpcd uhttpd; do
              if [ ! -x "/etc/init.d/$service" ]; then
                echo "Cannot enable LuCI: $service is not installed" >&2
                exit 1
              fi
            done
            /etc/init.d/rpcd enable
            /etc/init.d/uhttpd enable
            /etc/init.d/rpcd start
            /etc/init.d/uhttpd start
          '';
        };
      };

      # UCI packages are replaced wholesale. Dewclaw deletes every configuration
      # not declared in settings or listed here; retain UI/hardware-owned defaults.
      uci.retain = [
        "luci"
        "rpcd"
        "ubihealthd"
        "ubootenv"
        "uhttpd"
      ];

      uci.settings = {
        attendedsysupgrade = attendedSysupgrade;

        # Preserve password login on port 22 alongside the declared public keys.
        dropbear.dropbear.main = {
          enable = "1";
          PasswordAuth = "on";
          RootPasswordAuth = "on";
          Port = "22";
        };

        # LAN-only AP policy: preserve LAN access and reject other input/forwarding.
        # No logical WAN exists, so omit WAN rules, NAT, and inter-zone forwarding.
        # Not client isolation; revisit before adding routed networks or VLANs.
        firewall = {
          defaults = [
            {
              syn_flood = "1";
              input = "REJECT";
              output = "ACCEPT";
              forward = "REJECT";
            }
          ];
          zone.lan = {
            name = "lan";
            network = [ "lan" ];
            input = "ACCEPT";
            output = "ACCEPT";
            forward = "ACCEPT";
          };
        };

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
              proto = "dhcp";
            };
          };
          globals.globals = {
            ula_prefix = ulaPrefix;
            packet_steering = "1";
            dhcp_default_duid = dhcpDuid;
          };
          device = [
            {
              name = "br-lan";
              type = "bridge";
              ports = [ "lan1" "lan2" "wan" ];
              # Preserve DHCP reservations across firmware/port-MAC changes.
              macaddr = bridgeMac;
            }
          ];
        };

        wireless = {
          wifi-device = {
            radio0 = {
              type = "mac80211";
              path = "platform/soc@0/c000000.wifi";
              band = "2g";
              channel = channel2g;
              htmode = "HE20";
              cell_density = "0";
              country = "US";
            };
            radio1 = {
              type = "mac80211";
              path = "platform/soc@0/b00a040.wifi";
              band = "5g";
              channel = channel5g;
              htmode = "HE80";
              cell_density = "0";
              country = "US";
            };
          };
          wifi-iface = {
            ap_2g = wifiInterface "radio0";
            ap_5g = wifiInterface "radio1";
          };
        };

        system = {
          system = [
            (systemSettings // {
              inherit hostname;
            })
          ];
          timeserver.ntp.server = ntpServers;
        };

        dhcp = {
          dnsmasq = [
            {
              # Prevent reloads from starting the instance; the step above stops it.
              disabled = "1";
              # Also lets the stop handler restore direct upstream DNS resolution.
              resolvfile = "/tmp/resolv.conf.d/resolv.conf.auto";
            }
          ];
          # No local server/relay role: upstream DHCP/IPv6 crosses the bridge.
          # The AP's management DHCP client is configured separately in network.
          dhcp.lan = {
            interface = "lan";
            ignore = "1";
            ra = "disabled";
            dhcpv6 = "disabled";
            ndp = "disabled";
          };
          odhcpd.odhcpd = {
            maindhcp = "0";
            leasefile = "/tmp/odhcpd.leases";
            leasetrigger = "/usr/sbin/odhcpd-update";
            loglevel = "4";
            piodir = "/tmp/odhcpd-piodir";
            hostsdir = "/tmp/hosts";
          };
        };
      };
    };
in
{
  openwrt = {
    gl-b3000-a = mkAp {
      hostname = "gl-b3000-a";
      address = "192.168.0.8";
      bridgeMac = "94:83:c4:a4:d9:f4";
      ulaPrefix = "fdb4:1dea:9b6d::/48";
      dhcpDuid = "0004a18a8cac1bf9448ea3f90cb9f72fb52c";
      channel2g = "1";
      channel5g = "36";
    };

    gl-b3000-b = mkAp {
      hostname = "gl-b3000-b";
      address = "192.168.0.9";
      bridgeMac = "94:83:c4:a4:db:2a";
      ulaPrefix = "fd48:fae3:5e4c::/48";
      dhcpDuid = "0004554f4cb9cea04d4ca6ff42f47d98f926";
      channel2g = "11";
      channel5g = "149";
    };

    router = sharedManagement // {
      deploy = {
        host = "192.168.0.1";
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
              ipaddr = "192.168.0.1";
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
              local = "/lan/";
              domain = "lan";
              expandhosts = "1";
              authoritative = "1";
              readethers = "1";
              leasefile = "/tmp/dhcp.leases";
              resolvfile = "/tmp/resolv.conf.d/resolv.conf.auto";
              localservice = "1";
              ednspacket_max = "1232";
              address = [
                "/*.home.rosset.org.uk/192.168.0.4"
                "/*.home.rosset.pl/192.168.0.5"
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
          host = [
            {
              name = "morgoth";
              dns = "1";
              mac = "D0:50:99:51:30:68";
              ip = "192.168.0.4";
            }
            {
              mac = [ "84:47:09:A2:1A:01" ];
              ip = "192.168.0.5";
              name = "ecolite";
              dns = "1";
            }
            {
              ip = "192.168.0.8";
              name = "gl-b3000-a";
              dns = "1";
              mac = [ "94:83:C4:A4:D9:F4" ];
              tag = [ "AP" ];
            }
            {
              ip = "192.168.0.9";
              name = "gl-b3000-b";
              dns = "1";
              mac = [ "94:83:C4:A4:DB:2A" ];
              tag = [ "AP" ];
            }
            {
              ip = "192.168.0.11";
              name = "SLZB-MR4";
              dns = "1";
              mac = [ "00:4B:12:96:1B:3B" ];
            }
            {
              name = "bravia";
              dns = "1";
              mac = "94:DB:56:0A:D9:B4";
              ip = "192.168.0.62";
            }
            {
              name = "denon";
              dns = "1";
              mac = "00:05:CD:A1:91:BD";
              ip = "192.168.0.64";
            }
            {
              mac = "9C:8E:CD:24:53:DA";
              ip = "192.168.0.75";
              name = "amc04759-ffa3ef";
              dns = "1";
            }
          ];
          cname = [
            {
              cname = "home-assistant-cname";
              target = "morgoth";
            }
          ];
          domain = [
            {
              name = "home-assistant-host";
              ip = "192.168.0.5";
            }
            {
              name = "mqtt-broker";
              ip = "192.168.0.5";
            }
            {
              name = "zigbee2mqtt-host";
              ip = "192.168.0.5";
            }
            {
              name = "zigbee-coordinator";
              ip = "192.168.0.11";
            }
          ];
        };

        system = {
          system = [
            (systemSettings // {
              hostname = "router";
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
