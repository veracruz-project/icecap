{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    build = mkOption {
      internal = true;
      default = {};
      type = types.attrs;
    };

  };
}
