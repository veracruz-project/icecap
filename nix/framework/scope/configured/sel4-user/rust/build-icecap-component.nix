{ lib, hostPlatform, buildPackages
, buildRustPackageIncrementally, rustTargetName, crateUtils, elfUtils
, icecapPlat, icecapConfig, globalCrates
, libsel4, userC
, root-task-tls-lds
, root-task-eh-lds
}:

let
  patches = globalCrates._patches;
in

{ isRoot ? false
# TODO better way of overriding
, modifyExtraCargoConfig ? lib.id
, modifyExtra ? lib.id
, modifyExtraLastLayer ? lib.id
, ... /* TODO */
} @ args:

lib.fix (self: buildRustPackageIncrementally ({

  layers = with globalCrates; [
    [] [ icecap-sel4-sys ] [ icecap-std ]
  ];

  extraManifest = {
    profile.release = {
      codegen-units = 1;
      lto = true;
    };
  };

  extraCargoConfig = modifyExtraCargoConfig (crateUtils.clobber [
    {
      target.${rustTargetName}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ] ++ lib.optionals icecapConfig.debug [
        "--cfg=icecap_debug"
      ] ++ lib.optionals icecapConfig.benchmark [
        "--cfg=icecap_benchmark"
      ] ++ lib.optionals isRoot [
        "-C" "link-arg=-T${root-task-tls-lds}"
        # "-T" root-task-tls-lds
      ];
    }
  ]);

  extra = modifyExtra {
    LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = [
      "-I${libsel4}/include"
    ];
    buildInputs = [
      libsel4
      userC.${if isRoot then "rootLibs" else "nonRootLibs"}.icecap-runtime
    ];
    dontStrip = true;
    dontPatchELF = true;
  };

  extraLastLayer = modifyExtraLastLayer (attrs: {
    passthru = (attrs.passthru or {}) // {
      split = elfUtils.split "${self}/bin/${args.rootCrate.name}.elf";
    };
  });

} // builtins.removeAttrs args [
  "isRoot" "modifyExtraCargoConfig" "modifyExtra" "modifyExtraLastLayer"
]))
