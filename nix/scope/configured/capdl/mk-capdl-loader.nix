{ runCommand, linkFarm, writeText
, cpioUtils
, capdl-tool
, object-sizes, libsel4
, capdl-loader-core, libs
, icecapSrc
}:

{ cdl
, elfs-cpio
}:

let
  spec = runCommand "capdl_spec.c" {
    nativeBuildInputs = [
      capdl-tool
    ];
  } ''
    mkdir $out
    parse-capDL --code-dynamic-alloc --object-sizes=${object-sizes} --code=$out/spec.c ${cdl}
  '';
    # TODO consider parse-capDL --code-static-alloc

in
libs.mkRoot rec {
  passthru = {
    inherit spec elfs-cpio;
  };
  name = "capdl-loader-app";
  root = icecapSrc.relativeSplit "c/boot/${name}";
  extra.CAPDL_LOADER_SPEC_SRC = spec;
  extra.CAPDL_LOADER_CPIO_O = cpioUtils.mkObj {
    archive-cpio = elfs-cpio;
    symbolName = "_capdl_archive";
  };
  propagatedBuildInputs = with libs; [
    libsel4
    icecap-runtime-root
    icecap-pure
    icecap-utils

    capdl-loader-core
  ];
}
