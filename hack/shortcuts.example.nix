let
  topLevel = import ../.;

in topLevel.lib.fix (self: topLevel // topLevel.pkgs // topLevel.meta // (with self; {

  bt = buildTest;
  b = none.buildPackages;
  c = configured;

  v = tests.realm-vm.virt;
  vc = v.configured;
  vr = v.run;

  r = tests.realm-vm.rpi4;
  rb = v.run.boot;

}))
