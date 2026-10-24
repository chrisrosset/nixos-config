{ config, lib, ... }:
{
  services.tailscale = {
    # Bootstrap new hosts with a key provisioned outside the Nix store.
    authKeyFile = "/root/tailscale.key";

    enable = true;

    extraSetFlags = [
      # These are here to enable resolving *.home.rosset.pl via SplitDNS.
      "--accept-dns=true"
      "--accept-routes=true"
    ] ++ lib.optionals config.roles.server [
      # Servers offer Tailscale SSH and exit-node routing; personal devices do not.
      "--advertise-exit-node"
      "--ssh"
    ];

    openFirewall = true;

    useRoutingFeatures = if config.roles.server then "server" else "client";
  };

  # Enrolled hosts reconnect from persistent state and do not need the key.
  systemd.services.tailscaled-autoconnect.unitConfig.ConditionPathExists =
    "/root/tailscale.key";
}