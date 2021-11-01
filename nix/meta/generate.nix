{ lib, pkgs }:

let
  inherit (pkgs.dev) writeScript runtimeShell;
  inherit (pkgs.dev.icecap) icecapSrc generatedCrateManifests globalCrates;

  mkAction = actuallyDoIt: landmark: old: new: ''
    ${lib.optionalString (landmark != null) ''
      if ! test -f ${landmark}; then
        echo "${landmark} does not exist"
        false
      fi
    ''}
    ${lib.optionalString (!actuallyDoIt) ''
      if ! test -f ${old}; then
        echo "${old} does not exist"
        false
      fi
    ''}
    if ! cmp -s -- ${old} ${new}; then
      ${if actuallyDoIt
        then ''
          cp -vL --no-preserve=all ${new} ${old}
        ''
        else ''
          echo "${old} differs from ${new}"
          false
        ''
      }
    fi
  '';

  mkCratesFor = attrs: builtins.toFile "x.txt" (lib.concatStrings (lib.naturalSort (lib.mapAttrsToList (k: _: "${k}\n") attrs)));

  cratesForLinux = mkCratesFor globalCrates._cratesForLinux;
  cratesForSeL4 = mkCratesFor globalCrates._cratesForSeL4;

  mkCrateManifests = actuallyDoIt: writeScript "x.sh" ''
    #!${runtimeShell}
    set -e
    cd ${toString (icecapSrc.relativeRaw "rust")}
    pwd
    mkdir -p support
    ${mkAction actuallyDoIt "crates.nix" "support/crates-for-linux.txt" cratesForLinux}
    ${mkAction actuallyDoIt "crates.nix" "support/crates-for-seL4.txt" cratesForSeL4}
    ${mkAction actuallyDoIt "crates.nix" "Cargo.lock" generatedCrateManifests.lock}
    ${mkAction actuallyDoIt "crates.nix" "Cargo.toml" generatedCrateManifests.workspace}
    ${lib.concatStrings (lib.flip lib.mapAttrsToList generatedCrateManifests.realized (_: { relativePath, manifest }: ''
      ${mkAction actuallyDoIt "${relativePath}/crate.nix" "${relativePath}/Cargo.toml" manifest}
    ''))}
  '';

  mkAll = actuallyDoIt: writeScript "x.sh" ''
    #!${runtimeShell}
    set -e
    ${mkCrateManifests actuallyDoIt}
  '';

  seL4Dts = actuallyDoIt:
    let
      inherit (pkgs.dev.icecap) seL4EcosystemRepos;
      assocs = lib.mapAttrsToList (k: configured: {
        new = configured.deviceTreeConfigured.seL4;
        old = "${toString seL4EcosystemRepos.seL4.forceLocal.env}/tools/dts/${configured.selectIceCapPlat {
          # The alignment of these names is a coincidence
          rpi4 = "rpi4";
          virt = "virt";
        }}.dts";
      }) pkgs.none.icecap.configured;
    in
      writeScript "x.sh" ''
        #!${runtimeShell}
        set -e
        ${lib.concatMapStrings ({ new, old }: ''
          if ! cmp -s -- ${old} ${new}; then
            ${if actuallyDoIt
              then ''
                cp -vL --no-preserve=all ${new} ${old}
              ''
              else ''
                echo "${old} differs from ${new}"
                false
              ''
            }
          fi
        '') assocs}
      '';

in rec {

  update = mkAll true;
  check = mkAll false;

  seL4 = {
    update = seL4Dts true;
    check = seL4Dts false;
  };

}
