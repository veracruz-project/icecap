{ lib, runCommand
, cargo
, nixToToml, cratesIOIndexCache
, crateUtils
}:

{ rootCrate, extraManifest ? {} }:

let
  crates = lib.attrValues (crateUtils.closure rootCrate);

  workspace = nixToToml (crateUtils.clobber [
    {
      workspace.members = [ "src/${rootCrate.name}" ];
      workspace.exclude = [ "src/*" ];
    }
    extraManifest
  ]);

  src = crateUtils.collectDummies [] crates;

in
runCommand "Cargo.lock" {
  nativeBuildInputs = [
    cargo
  ];
  CARGO_HOME = cratesIOIndexCache;
} ''
  ln -s ${src} src
  ln -s ${workspace} Cargo.toml
  cargo generate-lockfile --offline
  mv Cargo.lock $out
''
