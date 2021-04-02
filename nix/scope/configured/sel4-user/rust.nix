{ lib
, buildIceCapCrateBin, globalCrates
, libs, liboutline
}:

let
  mk = crateName: overrides: buildIceCapCrateBin {
    rootCrate = globalCrates.${crateName};
    debug = true;
    extraLayers = [ [ "icecap-std" ] ];
    # debug = true;
    debug = false;
    extraManifest = {
      profile.release = {
        codegen-units = 1;
        opt-level = 3;
        lto = true;
      };
    };
    buildInputs = with libs; [
      liboutline
    ] ++ (overrides.buildInputs or []);
  };

in

lib.mapAttrs mk {

  fault-handler = {};
  serial-server = {};
  timer-server = {};
  event-server = {};
  resource-server = {};
  host-vmm = {};
  qemu-ring-buffer-server = {};
  idle = {};

}
