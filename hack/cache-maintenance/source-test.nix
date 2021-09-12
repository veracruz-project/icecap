let
  source = builtins.fetchGit {
    url = https://gitlab.com/arm-research/security/icecap/icecap.git;
    rev = builtins.getEnv "CURRENT_REV";
    ref = builtins.getEnv "CURRENT_REF";
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
