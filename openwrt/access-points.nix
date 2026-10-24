{
  lib,
  hosts,
  ipv4,
  sharedManagement,
  configurationOnlySteps,
  attendedSysupgrade,
  systemSettings,
}:

let
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
      host,
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
        host = ipv4 host;
        user = "root";
        sshConfig.HostKeyAlias = host.hostname;
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
              macaddr = lib.toLower host.mac;
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
              inherit (host) hostname;
            })
          ];
          # Use the router as the NTP server.
          timeserver.ntp = {
            server = [ (ipv4 hosts.router) ];
            use_dhcp = "0";
          };
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
  gl-b3000-a = mkAp {
    host = hosts.apA;
    ulaPrefix = "fdb4:1dea:9b6d::/48";
    dhcpDuid = "0004a18a8cac1bf9448ea3f90cb9f72fb52c";
    channel2g = "1";
    channel5g = "36";
  };

  gl-b3000-b = mkAp {
    host = hosts.apB;
    ulaPrefix = "fd48:fae3:5e4c::/48";
    dhcpDuid = "0004554f4cb9cea04d4ca6ff42f47d98f926";
    channel2g = "11";
    channel5g = "149";
  };
}
