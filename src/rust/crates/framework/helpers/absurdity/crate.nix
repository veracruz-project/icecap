{ mk }:

mk {
  nix.name = "absurdity";
  nix.passthru.buildScriptPath = "build.rs";
  nix.passthru.excludeFromBuild = true;
}
