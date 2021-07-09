{ lib
, buildIceCapCrate, globalCrates
, libs, liboutline
}:

let
  mk = crateName: overrides: buildIceCapCrate {
    rootCrate = globalCrates.${crateName};
    # debug = false;
    debug = true;
    extraLayers = [ [ globalCrates.icecap-std ] ];
    extraManifest = {
      profile.release = {
        codegen-units = 1;
        opt-level = 3;
        lto = true;
      };
    };
    extraArgs = {
      buildInputs = with libs; [
        liboutline
      ] ++ (overrides.buildInputs or []);
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
