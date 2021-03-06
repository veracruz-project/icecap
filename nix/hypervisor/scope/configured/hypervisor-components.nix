{ lib
, buildIceCapComponent, globalCrates
, genericComponents
}:

let
  mk = name: _: buildIceCapComponent {
    rootCrate = globalCrates."hypervisor-${name}";
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

} // {

  timer-server = genericComponents.icecap-generic-timer-server;

}
