# Baseline configuration shared by every host.
# Hardware and host-specific modules remain in each host's default.nix.
{
  imports = [
    ./cli.nix
    ./nix.nix
    ./roles.nix
    ./ssh.nix
    ./tailscale.nix
    ./users.nix
  ];
}
