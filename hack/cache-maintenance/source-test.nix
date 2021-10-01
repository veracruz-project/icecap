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
      drv = topLevel.meta.buildTest;
    in
      assert drv.outPath == (import ../..).meta.buildTest.outPath;
      drv;

}
