let
  topLevel = import ../.;

in topLevel.lib.fix (self: topLevel // (with self; {

  hh = meta.instances.hacking.hypervisor;
  vt = hh.virt;
  vc = vt.configured;
  v = vt.run;
  rt = hh.rpi4;
  r = rt.run.boot;

}))
