{ lib, pkgs }:

{

  host-kernel = lib.flip lib.mapAttrs pkgs.linux.icecap.linuxKernel.host
    (plat: linuxKernel: pkgs.dev.runCommand "host-kernel-${plat}" {} ''
      mkdir $out
      cp ${linuxKernel}/* $out
      cp ${linuxKernel.dev}/vmlinux $out
      cp ${pkgs.linux.icecap.uBoot.host.${plat}}/* $out
    '');

  host-tools = pkgs.musl.buildEnv {
    name = "host-tools";
    paths = with pkgs.musl.icecap; [
      icecap-host
      crosvm-9p-server
    ];
  };

  realm-kernel = pkgs.dev.runCommand "realm-kernel" {} ''
    mkdir $out
    cp ${pkgs.linux.icecap.linuxKernel.realm}/* $out
    cp ${pkgs.linux.icecap.linuxKernel.realm.dev}/vmlinux $out
  '';

  realm-libraries = lib.flip lib.mapAttrs pkgs.none.icecap.configured
    (plat: configured: pkgs.dev.linkFarm "realm-libraries-${plat}" ([
      { name = "libsel4"; path = configured.libsel4; }
    ] ++ (with configured.userC.nonRootLibs; [
      { name = "libicecap-runtime"; path = icecap-runtime; }
      { name = "libicecap-utils"; path = icecap-utils; }
      { name = "libicecap-pure"; path = icecap-pure; }
    ])));

  build-tools = pkgs.dev.buildEnv {
    name = "build-tools";
    paths = (with pkgs.dev.icecap; [
      icecap-show-backtrace
      crosvm-9p-server
    ]) ++ (with pkgs.none.buildPackages.icecap; [
      capdl-tool
      dyndl-serialize-spec
      icecap-serialize-runtime-config
    ]);
  };

}
