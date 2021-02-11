{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    build = mkOption {
      internal = true;
      default = {};
      type = types.attrs;
      description = ''
        Attribute set of derivations used to setup the system.
      '';
    };

  };
}
