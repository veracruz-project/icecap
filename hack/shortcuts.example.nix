let
  topLevel = import ../.;

in topLevel.lib.fix (self: topLevel // (with self; {

  hh = meta.instances.hacking.example;
  hv = hh.virt;
  hr = hh.rpi4;
  v = hv.run;
  vc = hv.configured;
  rb = hr.run.boot;

  lhv = pkgs.linux.icecap.linuxKernel.host.virt;
  lhvc = pkgs.linux.icecap.linuxKernel.host.virt.configEnv;

  sr = vc.sysroot-rs;
  sre = vc.sysroot-rs.env;

}))
