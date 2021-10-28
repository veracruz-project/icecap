let
  icecap = import ../..;

  inherit (icecap) lib pkgs meta;
  inherit (builtins) toPath;

  plat =
    let
      k = "ICECAP_PLAT";
      v = builtins.getEnv k;
    in if lib.stringLength v == 0 then throw "${k} must be set" else v;

  configured = pkgs.none.icecap.configured.${plat};

in icecap // {

  shadow-vmm = pkgs.musl.icecap.icecap-host;

  host =
    let
      inherit (pkgs.linux.icecap) linuxKernel;
      inherit (pkgs.none.icecap) platUtils;
      inherit (configured) icecapFirmware icecapPlat;

      defaultKernel = linuxKernel.host.${icecapPlat}.kernel;
    in

    { kernel ? null, initramfs, bootargs ? "" }:

    let
      kernel_ = if kernel == null then defaultKernel else toPath kernel;
    in
      platUtils.${icecapPlat}.bundle {
        firmware = icecapFirmware.image;
        payload = icecapFirmware.mkDefaultPayload {
          linuxImage = kernel_;
          initramfs = toPath initramfs;
          bootargs = lib.splitString " " bootargs;
        };
      };

  realm =
    let
      inherit (pkgs.linux.icecap) linuxKernel;
      inherit (configured) icecapFirmware mkLinuxRealm;
      
      defaultKernel = linuxKernel.realm.kernel;
    in

    { kernel ? null, initramfs, bootargs ? "" }:

    let
      kernel_ = if kernel == null then defaultKernel else toPath kernel;
    in
      mkLinuxRealm {
        kernel = kernel_;
        initrd = toPath initramfs;
        bootargs = lib.splitString " " bootargs;
      };

  # extra

  firmware = configured.icecapFirmware.image;
  everything = meta.buildTest;
  demo = meta.demos.realm-vm.${configured.icecapPlat}.run;

}
