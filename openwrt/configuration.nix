{ lib, pkgs, ... }:

let
  sshKeys = import ../data/ssh-keys.nix;

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
    {
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

      # Replaces the entire file: include every required public key here.
      etc."dropbear/authorized_keys".text =
        lib.concatStringsSep "\n" [
          sshKeys.ctr.lemur
          sshKeys.ctr.ecolite
        ] + "\n";

      # Generate locally with `openssl passwd -6`; encrypt the complete $6$ hash.
      # This sets the shared root password, not Dropbear's authentication policy.
      users.root.hashedPasswordSecret = "root_password_hash";

      # Decrypt wifi_password and root_password_hash only at deployment time.
      # The deploying user needs the SOPS key; plaintext must not enter Git/store.
      # Validate the hash before any AP changes, rather than pass null to Dewclaw.
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

      # Configuration-only adoption: do not refresh feeds or reconcile packages.
      # These are internal Dewclaw options, so default.nix pins its revision.
      deploySteps.distfeeds.apply = lib.mkForce ":";
      deploySteps.packages = {
        prepare = lib.mkForce "";
        copy = lib.mkForce "";
        apply = lib.mkForce ":";
      };
      deploySteps.disableDnsmasq = {
        # Stop after UCI is applied so the resolver uses DHCP-supplied DNS.
        # Keep the package installed; verify DNS again after reboot/upgrades.
        priority = 100;
        apply = ''
          /etc/init.d/dnsmasq disable
          /etc/init.d/dnsmasq stop
        '';
      };
      deploySteps.enableLuci = {
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
        # Keep firmware upgrades manual; rebuild images with installed packages.
        # Automatic search is only a UI check, not automatic installation.
        attendedsysupgrade = {
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
            {
              inherit hostname;
              timezone = "GMT0";
              zonename = "UTC";
              ttylogin = "0";
              log_size = "128";
              urandom_seed = "0";
              log_proto = "udp";
              conloglevel = "8";
              cronloglevel = "7";
            }
          ];
          timeserver.ntp.server = [
            "0.openwrt.pool.ntp.org"
            "1.openwrt.pool.ntp.org"
            "2.openwrt.pool.ntp.org"
            "3.openwrt.pool.ntp.org"
          ];
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
  };
}
