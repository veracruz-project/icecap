{ lib, hostPlatform
, buildRustPackageIncrementally, crateUtils
, mkGlobalCrates
, stripElfSplit
, stdenv
, globalCrates
, icecapPlat
}:

args:

# TODO profile abort
lib.fix (self: buildRustPackageIncrementally ({
  extraCargoConfig = crateUtils.clobber [
    {
      target.${hostPlatform.config}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ];
    }
    (args.extraCargoConfig or {})
  ];
  layers = with globalCrates; [
    [ icecap-sel4-sys ]
  ] ++ (args.extraLayers or []);
  debug = false;
  extraArgs = ({
    dontStrip = true;
    dontPatchELF = true;
    hardeningDisable = [ "all" ];
    passthru = {
      split = stripElfSplit "${self}/bin/${args.rootCrate.name}.elf";
    } // ((args.extraArgs or {}).passthru or {});
  } // builtins.removeAttrs (args.extraArgs or {}) [
    "passthru"
  ]);
} // builtins.removeAttrs args [
  "extraCargoConfig" "extraLayers" "extraArgs"
]))
