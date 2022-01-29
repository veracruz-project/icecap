{ lib
, buildIceCapComponent, globalCrates
}:

let
  mk = crateName: _: buildIceCapComponent {
    rootCrate = globalCrates.${crateName};
  };

in
lib.mapAttrs mk {

  icecap-generic-timer-server = null;

}
