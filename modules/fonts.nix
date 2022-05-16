{ config, pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      dejavu_fonts
      inconsolata
      fira-code
      fira-code-symbols
      freefont_ttf
      liberation_ttf # libre corefonts replacement
      source-code-pro
      terminus_font
      ubuntu_font_family
    ];
  };
}
