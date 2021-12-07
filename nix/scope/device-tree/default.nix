{ icecapSrc, dtb-helpers, raspios, linuxPkgs }:

let
  rpi4Orig = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
  rpi4OrigDecompiled = dtb-helpers.decompile rpi4Orig;

in
{
  host = rec {
    virt = dtb-helpers.compile (icecapSrc.relative "boot/host/virt/host.dts");
    rpi4 = with dtb-helpers; compile (catFiles [ rpi4OrigDecompiled (icecapSrc.relative "boot/host/rpi4/host.dtsa") ]);
    passthru = {
      inherit rpi4Orig rpi4OrigDecompiled;
    };
  };
  realm = {
    virt = dtb-helpers.compile (icecapSrc.relative "boot/realm/device-tree/virt.dts");
    rpi4 = dtb-helpers.compile (icecapSrc.relative "boot/realm/device-tree/rpi4.dts");
  };
}
