{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev) writeText;
  inherit (configured) mkRealm;

in rec {

  spec = mkRealm {
    script = ./ddl.py;
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        minimal.image = minimal.split;
      };
    };
  };

  minimal = configured.buildIceCapComponent {
    rootCrate = configured.callPackage ./minimal/crate.nix {};
    debug = true;
  };

}
