{
  devices = {
    desktop-tdvt7n5 = { id = "E3PJ3AS-ZHCTLJH-TCYN4IT-W3L37D5-CCB3IUS-4SVL6OT-JNEGUIO-F2V3QAQ"; };
    lemur = { id = "NERH7BX-NKD7OGJ-VVTEXLY-24S74DP-ZEZKZPY-XHMVSYD-OKFNYWU-V5K26AT"; };
    morgoth = { id = "OE4IIQA-T2P6VR4-IMW2TQR-NJBJQLW-WSEKB5O-S5KRZHC-RZPNJ56-P3OW7AH"; };
    motoz = { id = "JNF2A72-QVEYA6W-LA6T4TY-ESVVCSF-P46S6IL-NIL52QC-FSUJCWX-RY3EMQM"; };
    s71a = { id = "YHWSSJS-Y2F6IYO-VSAPY3F-INJGEXA-BL3DSBI-KQYWXNF-ZWNLYQK-HNQRPQZ"; };
    prometheus = { id = "RX2XURG-5LNTIQH-THW4HZY-GXYJSZD-4BNKFRZ-ELKYFKN-PRYIONK-ADKHDAQ"; };
  };

  groups = rec {
    pcs = [ "desktop-tdvt7n5" "lemur" "morgoth" "prometheus" ];
    phones = [ "motoz" "s71a" ];
    standard = pcs ++ phones;
  };
}
