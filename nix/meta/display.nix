{ lib, pkgs }:

{

  host-tools = pkgs.dev.buildEnv {
    name = "host-tools";
    paths = with pkgs.linux.icecap; [
      icecap-host
      crosvm-9p-server
    ];
  };

  build-tools = pkgs.dev.buildEnv {
    name = "build-tools";
    paths = with pkgs.dev.icecap; [
      dyndl-serialize-spec
      icecap-show-backtrace
      icecap-serialize-runtime-config
      crosvm-9p-server
    ];
  };

  host-kernel = lib.flip lib.mapAttrs pkgs.linux.icecap.linuxKernel.host
    (plat: linuxKernel: pkgs.dev.runCommand "host-kernel-${plat}" {} ''
      mkdir $out
      cp ${linuxKernel}/* $out
      cp ${linuxKernel.dev}/vmlinux $out
      cp ${pkgs.linux.icecap.uBoot.host.${plat}}/* $out
    '');

  realm-kernel = pkgs.dev.runCommand "realm-kernel" {} ''
    mkdir $out
    cp ${pkgs.linux.icecap.linuxKernel.realm}/* $out
    cp ${pkgs.linux.icecap.linuxKernel.realm.dev}/vmlinux $out
  '';

}
