{ lib, pkgs }:

let
  inherit (pkgs.dev) writeScript runtimeShell;
  inherit (pkgs.dev.icecap) icecapSrc generatedCrateManifests;

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

  mkCrateManifests = actuallyDoIt: writeScript "x.sh" ''
    #!${runtimeShell}
    set -e
    cd ${toString (icecapSrc.relativeRaw "rust")}
    pwd
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

in rec {

  update = mkAll true;
  check = mkAll false;

}
