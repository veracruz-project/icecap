let
  topLevel = import ../../.;

in topLevel.framework.lib.fix (self: topLevel // (with self; {

  hh = hypervisor.instances.hacking.example;
  hv = hh.virt;
  hr = hh.rpi4;
  v = hv.run;
  vc = hv.configured;
  rb = hr.run.boot;

  lhv = framework.pkgs.linux.icecap.linuxKernel.host.virt;
  lhvc = framework.pkgs.linux.icecap.linuxKernel.host.virt.configEnv;

  sr = vc.sysroot-rs;
  sre = vc.sysroot-rs.env;

}))
