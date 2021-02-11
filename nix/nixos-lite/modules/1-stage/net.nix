{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.net;

in {
  options = {

    net.interfaces = mkOption {
      default = {};
      type = types.unspecified;
    };

  };

  config = {

    initramfs.extraInitCommands = ''
      ${concatStrings (mapAttrsToList (interface: v: ''
        echo "setting up ${interface}..."
        ${optionalString (hasAttr "static" v) ''
          ip link set ${interface} up
          ip address add ${v.static} dev ${interface}
        ''}
      '') cfg.interfaces)}
    '';

  };
}
