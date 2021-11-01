let
  source = builtins.fetchGit {
    url = ../..;
    rev = builtins.getEnv "CURRENT_REV";
    submodules = true;
  };

  topLevel = import source;

in rec {

  inherit topLevel;

  test =
    let
      drv = topLevel.meta.buildTests.all;
    in
      assert drv.outPath == (import ../..).meta.buildTests.all.outPath;
      drv;

}
