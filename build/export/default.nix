let
  icecap = import ../..;

  inherit (icecap) lib pkgs meta;

  inherit (pkgs.linux.icecap) linuxKernel;
  inherit (pkgs.none.icecap) platUtils;
  inherit (configured) icecapFirmware icecapPlat mkLinuxRealm;

  inherit (builtins) toPath;

  plat =
    let
      k = "ICECAP_PLAT";
      v = builtins.getEnv k;
    in if lib.stringLength v == 0 then throw "${k} must be set" else v;

  configured = pkgs.none.icecap.configured.${plat};

in icecap // {

  shadow-vmm = pkgs.musl.icecap.icecap-host;

  host = { kernel ? null, initramfs, bootargs ? "" }:
    let
      defaultKernel = linuxKernel.host.${icecapPlat}.kernel;
    in
      platUtils.${icecapPlat}.bundle {
        firmware = icecapFirmware.image;
        payload = icecapFirmware.mkDefaultPayload {
          linuxImage = if kernel == null then defaultKernel else toPath kernel;
          initramfs = toPath initramfs;
          bootargs = lib.splitString " " bootargs;
        };
      };

  realm = { kernel ? null, initramfs, bootargs ? "" }:
    let
      defaultKernel = linuxKernel.realm.kernel;
    in
      mkLinuxRealm {
        kernel = if kernel == null then defaultKernel else toPath kernel;
        initrd = toPath initramfs;
        bootargs = lib.splitString " " bootargs;
      };

  # crates = { crateNames }:

  # shortcuts

  firmware = configured.icecapFirmware.image;
  everything = meta.buildTest;
  demo = meta.demos.realm-vm.${configured.icecapPlat}.run;

}
