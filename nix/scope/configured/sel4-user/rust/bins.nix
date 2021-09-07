{ lib
, buildIceCapCrate, globalCrates
, liboutline
}:

let
  # TODO move most of this into buildIceCapCrate, with better approach to composing overrides
  mk = crateName: buildIceCapCrate {
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
  };

in

lib.mapAttrs (crateName: _: mk crateName) {

  fault-handler = null;
  serial-server = null;
  timer-server = null;
  event-server = null;
  resource-server = null;
  host-vmm = null;
  realm-vmm = null;
  idle = null;

}
