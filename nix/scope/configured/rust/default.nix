{ hostPlatform
, buildRustPackageIncrementally, crateUtils
, mkGlobalCrates
, stripElfSplit
, stdenv
}:

self: with self; {

  globalCrates = mkGlobalCrates {
    seL4 = true;
    extraArgs = {
      inherit stdenv icecap-sel4-sys-gen;
    };
  };

  icecap-sel4-sys-gen = callPackage ./icecap-sel4-sys-gen {};
  inherit (icecap-sel4-sys-gen) liboutline;

  sysroot-rs = callPackage ./sysroot.nix {
    # HACK wasmtime violates some assertions in core
    release = true;
  };

  buildIceCapCrate = { rootCrate, extraLayers ? [], thirdPartyCrates ? [], extraPassthru ? {}, requiresLibs ? [], ... }@args:
    # TODO profile abort
    buildRustPackageIncrementally ({
      inherit callPackage;
      extraCargoConfig = {
        target.${hostPlatform.config}.rustflags = [ "--cfg=icecap_plat=\"${icecapPlat}\"" ];
      };
      layers = with globalCrates; [
        thirdPartyCrates
        [ icecap-sel4-sys ]
      ] ++ extraLayers;
      debug = true;
      dontStrip = true;
      dontPatchELF = true;
      hardeningDisable = [ "all" ];
      passthru = {
        graph = {
          "${crateUtils.kebabToCaml rootCrate.name}_rs" = [ "outline" ] ++ requiresLibs;
        };
      } // extraPassthru;
    } // builtins.removeAttrs args [ "extraLayers" "thirdPartyCrates" "extraPassthru" "requiresLibs" ]);

  buildIceCapCrateBin = { rootCrate, ... }@args:
    let
      self = buildIceCapCrate args;
    in
      self // {
        split = stripElfSplit "${self}/bin/${rootCrate.name}.elf";
      };

}
