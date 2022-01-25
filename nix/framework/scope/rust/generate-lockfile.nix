{ lib, runCommand
, cargo
, nixToToml, cratesIOIndexCache
, crateUtils
, strace
}:

{ rootCrates, extraManifest ? {} }:

let
  crates = lib.attrValues (crateUtils.closureMany rootCrates);

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
    # strace
  ];
  CARGO_HOME = cratesIOIndexCache;
} ''
  ln -s ${src} src
  ln -s ${workspace} Cargo.toml
  cargo generate-lockfile --offline
  mv Cargo.lock $out
''
  # strace -f -e trace=file cargo generate-lockfile --offline
