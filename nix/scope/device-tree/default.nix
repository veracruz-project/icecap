{ dtb-helpers, raspios, linuxPkgs }:

{
  host = rec {
    virt = dtb-helpers.compile ./host/virt.dts;
    rpi4 =
      let
        # orig = "${raspios.latest.boot}/bcm2711-rpi-4-b.dtb";
        orig = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
      in with dtb-helpers; compile (catFiles [ (decompile orig) ./host/rpi4.dtsa ]);
  };
  guest = {
    virt = dtb-helpers.compile ./guest/virt.dts;
    rpi4 = dtb-helpers.compile ./guest/rpi4.dts;
  };
}
