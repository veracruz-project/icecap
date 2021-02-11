{ runCommand
, mkCpioObj
, capdl-loader-lib
, capdl-tool
, object-sizes
, libs, linkFarm, writeText, libsel4
}:

{ cdl
, elfs-cpio
}:

let
  images = mkCpioObj {
    archive-cpio = elfs-cpio;
    symbolName = "_capdl_archive";
    libName = "images";
  };

  spec = runCommand "capdl_spec.c" {
    nativeBuildInputs = [
      capdl-tool
    ];
  } ''
    parse-capDL --code-dynamic-alloc --object-sizes=${object-sizes} --code=$out ${cdl}
  '';
    # parse-capDL --code-static-alloc --code=$out ${cdl}

in
libs.mkRoot rec {
  passthru = {
    inherit spec elfs-cpio;
  };
  name = "capdl-loader";
  root = {
    store =
      let
        mk = writeText "icecap.mk" ''
          exes += capdl-loader
          src-capdl-loader = ${src}
          ldlibs-capdl-loader := -Wl,--start-group -licecap_runtime -licecap_utils -licecap_pure -lcpio -lcapdl_support_hack -lcapdl-loader -limages -Wl,--end-group
        '';
        src = linkFarm "root" [
          { name = "spec.c";
            path = spec;
          }
        ];
      in runCommand "root" {} ''
        mkdir $out
        cp ${mk} $out/icecap.mk
      '';
  };
  propagatedBuildInputs = with libs; [
    libsel4
    icecap-autoconf
    icecap-runtime-root
    icecap-pure
    icecap-utils

    capdl-loader-lib
    images
  ];
}
