{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (configured) mkLinuxRealm;

in rec {
  spec = mkLinuxRealm {
    kernel = pkgs.linux.icecap.linuxKernel.realm.kernel;
    initramfs = realmUser.config.build.initramfs;
    bootargs = [
      "earlycon=icecap_vmm"
      "console=hvc0"
      "loglevel=7"
    ];
  };

  realmUser = pkgs.linux.icecap.nixosLite.eval {
    modules = [
      ./config.nix
    ];
  };
}
