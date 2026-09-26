{
  devices = {
    ecolite = { id = "QPTM6A6-GVFTW2G-HUOTXI2-QJMFEAL-Y33RN37-UK3YW2H-IJMDJRB-WC4DPQO"; };
    kraken = { id = "72OEOQW-CVVTDX5-SMWEO7N-ZGQ44NC-DD6MNAY-35HGXVQ-EU5EMLH-3Z5UFQM"; };
    lemur = { id = "NERH7BX-NKD7OGJ-VVTEXLY-24S74DP-ZEZKZPY-XHMVSYD-OKFNYWU-V5K26AT"; };
    morgoth = { id = "LNKLMY5-K24R5GI-LMBAEW3-6HT4WC2-S4LROCC-KWD3KDR-L7RAHZG-GA57NAF"; };
    open = { id = "BFGOSLA-GZZCU7J-6PVJJPO-5BALYAQ-IIY4DQL-HZXFNSB-NNL6WAC-EGKFJAA"; };
    s71a = { id = "YHWSSJS-Y2F6IYO-VSAPY3F-INJGEXA-BL3DSBI-KQYWXNF-ZWNLYQK-HNQRPQZ"; };
    tiamat = { id = "IMZKZNB-5GZ2337-2B4RUKT-YTKPS2E-O5Y7UNS-KUYGVAW-4L5MFBW-UMIK4AU"; };
    tidemill = { id = "O6V775I-GTRMUXR-KOT6V2J-EYQMD6G-GROKWV5-KCL5IA6-44XO7XQ-2O6AKAG"; };
  };

  groups = rec {
    pcs = [ "ecolite" "kraken" "lemur" "morgoth" ];
    phones = [ "s71a" "open" ];
    standard = pcs ++ phones;
    oneplusPhotos = [ "kraken" "lemur" "morgoth" ] ++ phones;
  };
}
