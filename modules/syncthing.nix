{
  devices = {
    lemur = { id = "NERH7BX-NKD7OGJ-VVTEXLY-24S74DP-ZEZKZPY-XHMVSYD-OKFNYWU-V5K26AT"; };
    morgoth = { id = "OE4IIQA-T2P6VR4-IMW2TQR-NJBJQLW-WSEKB5O-S5KRZHC-RZPNJ56-P3OW7AH"; };
    s71a = { id = "YHWSSJS-Y2F6IYO-VSAPY3F-INJGEXA-BL3DSBI-KQYWXNF-ZWNLYQK-HNQRPQZ"; };
    prometheus = { id = "RX2XURG-5LNTIQH-THW4HZY-GXYJSZD-4BNKFRZ-ELKYFKN-PRYIONK-ADKHDAQ"; };
  };

  groups = rec {
    pcs = [ "lemur" "morgoth" "prometheus" ];
    phones = [ "s71a" ];
    standard = pcs ++ phones;
  };
}
