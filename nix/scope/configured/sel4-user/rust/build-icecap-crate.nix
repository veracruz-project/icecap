{ lib, hostPlatform
, buildRustPackageIncrementally, crateUtils, elfUtils
, icecapPlat, globalCrates
}:

{ extraLayers ? [], extraCargoConfig ? {}, extra ? {}, ... } @ args:

lib.fix (self: buildRustPackageIncrementally ({
  extraCargoConfig = crateUtils.clobber [
    {
      target.${hostPlatform.config}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ];
    }
    extraCargoConfig
  ];
  layers = [
    [ globalCrates.icecap-sel4-sys ]
  ] ++ extraLayers;
  debug = false;
  extra = attrs: 
    let
      # TODO HACK find better way to compose these overrides
      next = (if lib.isAttrs extra then lib.const extra else extra) attrs;
    in {
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
