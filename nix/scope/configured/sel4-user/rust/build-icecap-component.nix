{ lib, hostPlatform, buildPackages
, buildRustPackageIncrementally, rustTargetName, crateUtils, elfUtils
, icecapPlat, icecapConfig, globalCrates
, libsel4, libs
}:

let
  patches = globalCrates._patches;
in

{ ... /* TODO */ } @ args:

lib.fix (self: buildRustPackageIncrementally ({

  layers = with globalCrates; [
    [] [ icecap-sel4-sys ] [ icecap-std ]
  ];

  extraManifest = {
    profile.release = {
      codegen-units = 1;
      lto = true;
    };
    patch.crates-io = {
      dlmalloc.path = patches.dlmalloc.store;
    };
  };

  extraManifestEnv = {
    patch.crates-io = {
      dlmalloc.path = patches.dlmalloc.env;
    };
  };

  extraCargoConfig = crateUtils.clobber [
    {
      target.${rustTargetName}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ] ++ lib.optionals icecapConfig.debug [
        "--cfg=icecap_debug"
      ] ++ lib.optionals icecapConfig.benchmark [
        "--cfg=icecap_benchmark"
      ];
    }
  ];

  extra = {
    LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = [
      "-I${libsel4}/include"
      "-I${libs.icecap-autoconf}/include"
    ];
    buildInputs = [
      libsel4 libs.icecap-autoconf libs.icecap-runtime libs.icecap-utils
    ];
    dontStrip = true;
    dontPatchELF = true;
    hardeningDisable = [ "all" ];
  };

  extraLastLayer = attrs: {
    passthru = (attrs.passthru or {}) // {
      split = elfUtils.split "${self}/bin/${args.rootCrate.name}.elf";
    };
  };

} // builtins.removeAttrs args [
  # TODO
]))
