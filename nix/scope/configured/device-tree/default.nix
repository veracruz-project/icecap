{ dtbHelpers, platUtils, raspios, selectIceCapPlat }:

{
  seL4 = selectIceCapPlat {
    virt = dtbHelpers.decompile platUtils.virt.extra.dtb;
    rpi4 = dtbHelpers.decompile "${raspios.latest.boot}/bcm2711-rpi-4-b.dtb";
  };
}
