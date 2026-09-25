{ ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
      randomizedDelaySec = "45min";
    };

    optimise = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "45min";
    };
  };
}