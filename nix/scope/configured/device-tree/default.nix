{ dtb-helpers, platUtils, raspios, selectIceCapPlat }:

{
  seL4 = selectIceCapPlat {
    virt = dtb-helpers.decompile platUtils.virt.extra.dtb;
    rpi4 = dtb-helpers.decompile "${raspios.latest.boot}/bcm2711-rpi-4-b.dtb";
  };
}
