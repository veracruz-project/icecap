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
    # patch.crates-io = {
    #   dlmalloc.path = patches.dlmalloc.store;
    # };
  };

  # extraManifestEnv = {
  #   patch.crates-io = {
  #     dlmalloc.path = patches.dlmalloc.env;
  #   };
  # };

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
    (lib.optionalAttrs isRoot {
      # target.${rustTargetName}.rustc-link-arg-bin = [ "-T" root-task-tls-lds ];
      target.${rustTargetName}.rustflags = [ "-C" "link-arg=-T${root-task-tls-lds}" ];
    })
  ];

  extra = {
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

  extraLastLayer = attrs: {
    passthru = (attrs.passthru or {}) // {
      split = elfUtils.split "${self}/bin/${args.rootCrate.name}.elf";
    };
  };

} // builtins.removeAttrs args [
  "isRoot"
]))
