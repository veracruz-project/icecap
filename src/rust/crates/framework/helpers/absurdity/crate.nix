{ mkExclude }:

mkExclude {
  nix.name = "absurdity";
  nix.passthru.buildScriptPath = "build.rs";
}
