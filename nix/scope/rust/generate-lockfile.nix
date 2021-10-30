{ lib, runCommand
, cargo
, nixToToml, cratesIOIndexCache
, crateUtils
}:

{ rootCrates, extraManifest ? {} }:

let
  crates = lib.attrValues (crateUtils.closure' rootCrates);

  workspace = nixToToml (crateUtils.clobber [
    {
      workspace.resolver = "2";
      workspace.members = map (crate: "src/${crate.name}") rootCrates;
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
