{ lib
, buildIceCapCrate, globalCrates
, liboutline
}:

let
  # TODO move most of this into buildIceCapCrate, with better approach to composing overrides
  mk = crateName: args: buildIceCapCrate ({
    rootCrate = globalCrates.${crateName};
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
  } // args);

in

(lib.mapAttrs (crateName: args: mk crateName args) {

  fault-handler = {};
  serial-server = {};
  timer-server = {};
  event-server = {};
  resource-server = {};
  benchmark-server = {};
  host-vmm = {};
  realm-vmm = {};
  idle = {};

} // {
  inherit mk;
})
