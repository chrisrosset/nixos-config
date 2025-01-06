{
  devices = {
    kraken = { id = "72OEOQW-CVVTDX5-SMWEO7N-ZGQ44NC-DD6MNAY-35HGXVQ-EU5EMLH-3Z5UFQM"; };
    lemur = { id = "NERH7BX-NKD7OGJ-VVTEXLY-24S74DP-ZEZKZPY-XHMVSYD-OKFNYWU-V5K26AT"; };
    morgoth = { id = "LNKLMY5-K24R5GI-LMBAEW3-6HT4WC2-S4LROCC-KWD3KDR-L7RAHZG-GA57NAF"; };
    s71a = { id = "YHWSSJS-Y2F6IYO-VSAPY3F-INJGEXA-BL3DSBI-KQYWXNF-ZWNLYQK-HNQRPQZ"; };
    open = { id = "BFGOSLA-GZZCU7J-6PVJJPO-5BALYAQ-IIY4DQL-HZXFNSB-NNL6WAC-EGKFJAA"; };
  };

  groups = rec {
    pcs = [ "kraken" "lemur" "morgoth" ];
    phones = [ "s71a" "open" ];
    standard = pcs ++ phones;
  };
}
