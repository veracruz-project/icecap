{ lib
, buildIceCapCrate, globalCrates
, libs, liboutline, libsel4
}:

let
  mk = crateName: {}: buildIceCapCrate {
    rootCrate = globalCrates.${crateName};
    debug = false;
    # debug = true;
    extraLayers = [ [ globalCrates.icecap-std ] ];
    extraManifest = {
      profile.release = {
        codegen-units = 1;
        opt-level = 3;
        lto = true;
      };
    };
    extra = attrs: {
      buildInputs = (attrs.buildInputs or []) ++ [
        liboutline
      ];
    };
  };

in

lib.mapAttrs mk {

  fault-handler = {};
  serial-server = {};
  timer-server = {};
  event-server = {};
  resource-server = {};
  host-vmm = {};
  realm-vmm = {};
  idle = {};

}
