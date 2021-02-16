{ lib
, buildDunePackage
, ocamlPackages
, buildPackagesOCaml
, mirage-icecap
, mkMirageLibrary
}:

mkMirageLibrary {
  main = buildDunePackage rec {
    pname = "main";
    version = "0.1";
    src = lib.cleanSource ./mirage-ml;
    nativeBuildInputsOCaml = with buildPackagesOCaml; [
      lwt_ppx
    ];
    propagatedBuildInputsOCaml = with ocamlPackages; [
      lwt
      mirage-icecap
      base yojson hex
      # TODO why is this necessary?
      lwt_ppx
    ];
  };
}
