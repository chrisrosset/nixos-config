{ config, pkgs, ... }:

{
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      dejavu_fonts
      inconsolata
      liberation_ttf # libre corefonts replacement
      source-code-pro
      terminus_font
      ubuntu_font_family
    ];
  };
}
