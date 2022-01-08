{ lib, config, pkgs, ... }:

with lib;

# TODO

{

  options.instance = {
    host.enable = mkOption {
      type = types.bool;
      default = false;
    };
    realm.enable = mkOption {
      type = types.bool;
      default = false;
    };
    plat = mkOption {
      type = types.unspecified;
    };
  };

  config = {
    lib.instance.mkNftablesScriptForNat = { physicalIface }: pkgs.writeText "nat.nft" ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority 0;
        }
        chain postrouting {
          type nat hook postrouting priority 100;
          oifname "${physicalIface}" masquerade
        }
      }
    '';
  };

}
