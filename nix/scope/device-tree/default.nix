{ dtb-helpers, raspios, pkgs_linux }:

{
  host = rec {
    rpi4 =
      let
        # orig = "${raspios.latest.boot}/bcm2711-rpi-4-b.dtb";
        # orig = ../../../../../local/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb;
        orig = "${pkgs_linux.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
      in with dtb-helpers; compile (catFiles [ (decompile orig) ./host/rpi4.dtsa ]);
    virt = dtb-helpers.compile ./host/virt.dts;
    dts = {
      rpi4 = with dtb-helpers; decompile rpi4;
    };
  };
  guest = {
    virt = dtb-helpers.compile ./guest/virt.dts;
    rpi4 = dtb-helpers.compile ./guest/rpi4.dts;
  };
}
