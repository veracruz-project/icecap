let
  topLevel = import ../.;

in topLevel.lib.fix (self: topLevel // (with self; {

  vt = meta.tests.realm-vm.virt;
  vc = vt.configured;
  v = vt.run;

  rt = meta.tests.realm-vm.rpi4;
  r = rt.run.boot;

}))
