{ lib
, buildIceCapComponent, globalCrates
}:

let
  mk = crateName: _: buildIceCapComponent {
    rootCrate = globalCrates.${crateName};
  };

in
lib.mapAttrs mk {

  fault-handler = null;
  serial-server = null;
  timer-server = null;
  event-server = null;
  resource-server = null;
  benchmark-server = null;
  host-vmm = null;
  realm-vmm = null;
  idle = null;

}
