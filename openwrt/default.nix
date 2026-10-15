{ pkgs ? import <nixpkgs> { } }:

let
  dewclaw = builtins.fetchTarball {
    url = "https://github.com/MakiseKurisu/dewclaw/archive/4ef68ba1ab5afaafe1a22217f7a6beb005bb6ecd.tar.gz";
    sha256 = "0i7il3h7jp8l6zzwckcljds6kqs7bsm1rw3zcsfwrfaclx6ljlm7";
  };
in
import dewclaw {
  inherit pkgs;
  configuration = ./configuration.nix;
}
