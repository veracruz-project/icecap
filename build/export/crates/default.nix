let
  icecap = import ../../..;

  inherit (icecap) lib pkgs meta;
  inherit (pkgs.dev) runCommand writeText writeScript;
  inherit (pkgs.dev.icecap) nixToToml crateUtils icecapSrc;

  pathBetween = here: there: import (runCommand "x.nix" {
    nativeBuildInputs = [ pkgs.dev.python3 ];
  } ''
    python3 -c 'from os.path import relpath; print("\"{}\"".format(relpath("${there}", "${here}")))' > $out
  '');

  ensureDot = s: if lib.hasPrefix "." s then s else "./${s}";

  appendToManifest = base: extra: runCommand "Cargo.toml" {
    nativeBuildInputs = [
      pkgs.dev.python3Packages.toml
    ];
  } ''
    cat ${frontmatter} > $out
    echo >> $out
    python3 ${./append-to-manifest.py} ${builtins.toFile "x.json" (builtins.toJSON extra)} < ${base} >> $out
  '';

  frontmatter = builtins.toFile "frontmatter.toml" ''
    # This file is generated by the IceCap build system.
    # It is checked-in to version control for convenience and to serve as a reference.
  '';

  realize = crates:
    with crateUtils;
    let
    in
      lib.fix (self: lib.flip lib.mapAttrs crates (_: crate:
        let
          inherit (crate.hack) elaboratedNix rest;

          paths = lib.flip lib.mapAttrsRecursive elaboratedNix.local (_: v:
            if !lib.isList v then v else lib.listToAttrs (map (otherCrate: lib.nameValuePair otherCrate.name {
              path = ensureDot (pathBetween
                (toString elaboratedNix.hack.path)
                (toString otherCrate.hack.elaboratedNix.hack.path));
            }) v)
          );

          relativePath = pathBetween
            (toString (icecapSrc.relativeRaw "rust"))
            (toString elaboratedNix.hack.path);

          base = writeText "Cargo.toml" ''
            [package]
            name = "${elaboratedNix.name}"
            version = "0.1.0"
            edition = "2018"
            ${lib.optionalString (elaboratedNix.buildScriptHack != null) ''
              build = "build.rs"
            ''}
            ${lib.optionalString (lib.hasAttr "lib" rest) ''
              [lib]
            ''}
            ${lib.optionalString (lib.hasAttr "features" rest) ''
              [features]
            ''}
          '';

          manifest = appendToManifest base (lib.recursiveUpdate rest paths);
        in {
          inherit relativePath manifest;
        }
      ))
    ;

  configured = pkgs.none.icecap.configured.virt.override' { debug = true; };

  globalCrates = pkgs.dev.icecap.globalCrates._localCrates;

  realized = realize globalCrates;

  links = pkgs.dev.linkFarm "crates" (
    lib.flip lib.mapAttrsToList realized (_: { relativePath, manifest }: {
      name = "${relativePath}/Cargo.toml";
      path = manifest;
    })
  );

  script = writeScript "clobber.sh" ''
    #!${pkgs.dev.runtimeShell}
    set -e
    cd ${toString (icecapSrc.relativeRaw "rust")}
    ${lib.concatStrings (lib.flip lib.mapAttrsToList realized (_: { relativePath, manifest }: ''
      test -f ${relativePath}/crate.nix
      cp -vL --no-preserve=all ${manifest} ${relativePath}/Cargo.toml
    ''))}
  '';

in {
  inherit realized links script;
}
