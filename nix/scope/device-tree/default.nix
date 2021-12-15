{ lib, icecapSrc, byIceCapPlat, platUtils, dtb-helpers, raspios, linuxPkgs }:

let
  outerOrig = {
    rpi4 = "${linuxPkgs.icecap.linuxKernel.host.rpi4.dtbs}/broadcom/bcm2711-rpi-4-b.dtb";
    virt = platUtils.virt.extra.dtb;
  };

in
{
  host = byIceCapPlat (plat: rec {
    dtb = with dtb-helpers; compile (catFiles [
      orig.dts
      (icecapSrc.relative "support/hypervisor/host/common/host.dtsa")
      (icecapSrc.relative "support/hypervisor/host/${plat}/host.dtsa")
    ]);
    orig = {
      dtb = outerOrig.${plat};
      dts = dtb-helpers.decompile orig.dtb;
    };
  });
  realm = byIceCapPlat (plat: with dtb-helpers; compile (catFiles [
    (icecapSrc.relative "support/hypervisor/realm/device-tree/base.dts")
    (icecapSrc.relative "support/hypervisor/realm/device-tree/${plat}.dtsa")
  ]));
}
