{ ... }:
{
  services.udev = {
    extraHwdb = ''
      evdev:input:b0003v04D9p4545*
        KEYBOARD_KEY_70039=backspace
        KEYBOARD_KEY_7008a=leftctrl
        KEYBOARD_KEY_7008b=rightctrl
    '';
  };
}
