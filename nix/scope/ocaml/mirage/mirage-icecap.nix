{ lib
, icecapSrc
, buildDunePackage
, ocamlPackages, buildPackagesOCaml
}:

buildDunePackage rec {
  pname = "mirage-icecap";
  version = "0.1";
  src = icecapSrc.relative "ocaml/mirage-icecap";
  nativeBuildInputsOCaml = with buildPackagesOCaml; [
    lwt_ppx
  ];
  propagatedBuildInputsOCaml = with ocamlPackages; [
    cstruct
    lwt
    lwt-dllist

    mirage-time-lwt
    mirage-net-lwt
    mirage-protocols-lwt
    mirage-clock-lwt
    mirage-clock-freestanding
    mirage-random
    mirage-types-lwt
    arp-mirage
    ethernet
    tcpip

    # TODO why necessary?
    lwt_ppx
  ];
}
