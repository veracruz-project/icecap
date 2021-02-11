{ lib, config, pkgs, ... }:

with lib;

let
  cfgInitramfs = config.initramfs.net;
  cfg = config.net;

in {
  options = {

    initramfs.net.interfaces = mkOption {
      default = {};
      type = types.unspecified;
    };

    net.interfaces = mkOption {
      default = {};
      type = types.unspecified;
    };

  };

  config = {

    initramfs.mntCommands = ''
      ${concatStrings (mapAttrsToList (interface: v: ''
        echo "setting up ${interface}..."
        ${optionalString (hasAttr "static" v) ''
          ip link set ${interface} up
          ip address add ${v.static} dev ${interface}
        ''}
      '') cfgInitramfs.interfaces)}
    '';

    initramfs.extraNextInit = ''
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
