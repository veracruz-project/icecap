{ lib, pkgs }:

let
  inherit (pkgs.dev) writeScript runtimeShell;
  inherit (pkgs.dev.icecap) icecapSrc generatedCrateManifests;

in rec {

  all = writeScript "clobber-all.sh" ''
    #!${runtimeShell}
    set -e
    ${crateManifests}
  '';

  crateManifests = writeScript "clobber-crate-manifests.sh" ''
    #!${runtimeShell}
    set -e
    cd ${toString (icecapSrc.relativeRaw "rust")}
    ${lib.concatStrings (lib.flip lib.mapAttrsToList generatedCrateManifests.realized (_: { relativePath, manifest }: ''
      test -f ${relativePath}/crate.nix
      if ! cmp -s -- ${manifest} ${relativePath}/Cargo.toml; then
        cp -vL --no-preserve=all ${manifest} ${relativePath}/Cargo.toml
      fi
    ''))}
  '';

}
