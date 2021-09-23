{ dtb-helpers, raspios, linuxPkgs }:

let
  rpi4Orig = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
  rpi4OrigDecompiled = dtb-helpers.decompile rpi4Orig;

in
{
  host = rec {
    virt = dtb-helpers.compile ./host/virt.dts;
    rpi4 = with dtb-helpers; compile (catFiles [ rpi4OrigDecompiled ./host/rpi4.dtsa ]);
    passthru = {
      inherit rpi4Orig rpi4OrigDecompiled;
    };
  };
  realm = {
    virt = dtb-helpers.compile ./realm/virt.dts;
    rpi4 = dtb-helpers.compile ./realm/rpi4.dts;
  };
}
