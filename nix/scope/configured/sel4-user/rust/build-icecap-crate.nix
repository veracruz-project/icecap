{ lib, hostPlatform, buildPackages
, buildRustPackageIncrementally, rustTargetName, crateUtils, elfUtils
, icecapPlat, globalCrates
, libsel4, libs
}:

{ extraLayers ? [], extraCargoConfig ? {}, extra ? {}, ... } @ args:

lib.fix (self: buildRustPackageIncrementally ({
  extraCargoConfig = crateUtils.clobber [
    {
      target.${rustTargetName}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ];
    }
    extraCargoConfig
  ];
  layers = [
    [] [ globalCrates.icecap-sel4-sys ]
  ] ++ extraLayers;
  debug = false;
  extra = attrs: 
    let
      # TODO HACK find better way to compose these overrides
      next = (if lib.isAttrs extra then lib.const extra else extra) attrs;
    in {
      preBuild = ''
        export BINDGEN_EXTRA_CLANG_ARGS="$NIX_CFLAGS_COMPILE"
      '';
      buildInputs = (attrs.buildInputs or []) ++ [
        libsel4 libs.icecap-autoconf libs.icecap-runtime libs.icecap-utils
      ];
      LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
      dontStrip = true;
      dontPatchELF = true;
      hardeningDisable = [ "all" ];
      passthru = (attrs.passthru or {}) // {
        split = elfUtils.split "${self}/bin/${args.rootCrate.name}.elf";
      } // (next.passthru or {});
    } // builtins.removeAttrs next [
      "passthru"
    ];
} // builtins.removeAttrs args [
  "extraLayers" "extraCargoConfig" "extra"
]))
