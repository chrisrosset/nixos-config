{ config, pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      dejavu_fonts
      fira-code
      fira-code-symbols
      freefont_ttf
      inconsolata
      liberation_ttf # libre corefonts replacement
      source-code-pro
      terminus_font
      ubuntu-classic
    ];
  };
}
