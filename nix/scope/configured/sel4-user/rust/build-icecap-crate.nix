{ lib, hostPlatform
, buildRustPackageIncrementally, crateUtils
, mkGlobalCrates
, elfUtils
, stdenv
, globalCrates
, icecapPlat
}:

{ extraLayers ? [], extraCargoConfig ? {}, extra ? {}, ... } @ args:

# TODO profile abort
lib.fix (self: buildRustPackageIncrementally ({
  extraCargoConfig = crateUtils.clobber [
    {
      target.${hostPlatform.config}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ];
    }
    extraCargoConfig
  ];
  layers = with globalCrates; [
    [ icecap-sel4-sys ]
  ] ++ extraLayers;
  debug = false;
  extra = attrs: 
    let
      next = (if lib.isAttrs extra then lib.const extra else extra) attrs;
    in {
      dontStrip = true;
      dontPatchELF = true;
      hardeningDisable = [ "all" ];
      passthru = attrs.passthru // {
        split = elfUtils.split "${self}/bin/${args.rootCrate.name}.elf";
      } // (next.passthru or {});
    } // builtins.removeAttrs next [
      "passthru"
    ];
} // builtins.removeAttrs args [
  "extraLayers" "extraCargoConfig" "extra"
]))
