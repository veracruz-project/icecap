let
  icecap = import ../..;

  inherit (icecap) lib pkgs;

  byPlat = f: lib.flip lib.mapAttrs pkgs.none.icecap.configured
    (_: configured: f {
      inherit configured;
    });

in {

  icecap-host = pkgs.musl.icecap.icecap-host;

  host = byPlat (

    { configured }:

    let
      inherit (pkgs.linux.icecap) linuxKernel;
      inherit (pkgs.none.icecap) platUtils;
      inherit (configured) icecapFirmware icecapPlat;
      
      defaultKernel = linuxKernel.host.${icecapPlat}.kernel;
    in

    { kernel ? null, initramfs, bootargs }:

    let
      kernel_ = if kernel == null then defaultKernel else lib.toPath kernel;
    in
      platUtils.${icecapPlat}.bundle {
        firmware = icecapFirmware.image;
        payload = icecapFirmware.mkDefaultPayload {
          linuxImage = kernel;
          inherit initramfs;
          bootargs = lib.splitString bootargs;
        };
      }
  );

  realm = byPlat (

    { configured }:

    let
      inherit (pkgs.linux.icecap) linuxKernel;
      inherit (configured) icecapFirmware mkLinuxRealm;
      
      defaultKernel = linuxKernel.realm.kernel;
    in

    { kernel ? null, initramfs, bootargs }:

    let
      kernel_ = if kernel == null then defaultKernel else lib.toPath kernel;
    in
      mkLinuxRealm {
        kernel = kernel_;
        initrd = lib.toPath initramfs;
        bootargs = lib.splitString bootargs;
      }
  );

}
