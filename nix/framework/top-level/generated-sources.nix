{ lib, pkgs }:

let
  inherit (pkgs.dev) writeScript runtimeShell;
  inherit (pkgs.dev.icecap) icecapSrc generatedCrateManifests globalCrates;

  plan = {
    "support/crates-for-linux.txt" = {
      landmark = "crates.nix";
      path = globalCrates._cratesForTxt.linux;
    };
    "support/crates-for-seL4.txt" = {
      landmark = "crates.nix";
      path = globalCrates._cratesForTxt.seL4;
    };
    "Cargo.lock" = {
      landmark = "crates.nix";
      path = generatedCrateManifests.lock;
    };
    "Cargo.toml" = {
      landmark = "crates.nix";
      path = generatedCrateManifests.workspace;
    };
  } // lib.flip lib.mapAttrs' generatedCrateManifests.realized (_: { relativePath, manifest }: {
    name = "${relativePath}/Cargo.toml";
    value = {
      landmark = "${relativePath}/crate.nix";
      path = manifest;
    };
  });

  mkAction = actuallyDoIt: landmark: src: dst: ''
    ${lib.optionalString (landmark != null) ''
      if ! test -f ${landmark}; then
        echo "${landmark} does not exist"
        false
      fi
    ''}
    ${lib.optionalString (!actuallyDoIt) ''
      if ! test -f ${dst}; then
        echo "${dst} does not exist"
        false
      fi
    ''}
    if ! cmp -s -- ${dst} ${src}; then
      ${if actuallyDoIt
        then ''
          cp -vL --no-preserve=all ${src} ${dst}
        ''
        else ''
          echo "${dst} differs from ${src}"
          false
        ''
      }
    fi
  '';

  script = actuallyDoIt: writeScript "x.sh" ''
    #!${runtimeShell}
    set -e
    cd ${toString (icecapSrc.relativeRaw "rust")}
    ${lib.concatStrings (lib.mapAttrsToList (dst: { landmark, path }: ''
      ${mkAction actuallyDoIt landmark path dst}
    '') plan)}
  '';

in rec {

  inherit plan;

  update = script true;
  check = script false;

}
