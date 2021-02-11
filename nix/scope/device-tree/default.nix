{ dtb-helpers, raspbian, linuxKernel }:

{
  guest = dtb-helpers.compile ./guest.dts;
  host = rec {
    rpi4 =
      let
        # orig = "${raspbian.latest.boot}/bcm2711-rpi-4-b.dtb";
        # orig = ../../../../../local/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb;
        orig = "${linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
      in with dtb-helpers; compile (catFiles [ (decompile orig) ./host/rpi4.dtsa ]);
    virt = dtb-helpers.compile ./host/virt.dts;
    dts = {
      rpi4 = with dtb-helpers; decompile rpi4;
    };
  };
}
