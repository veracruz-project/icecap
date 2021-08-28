{ busybox }:

self: with self;

{
  eval = callPackage ./eval.nix {};

  mkExtraUtils = callPackage ./pkgs/mk-extra-utils.nix {};
  mkNixInitramfs = callPackage ./pkgs/mk-nix-initramfs.nix {};
  mkBusyboxInitramfs = callPackage ./pkgs/mk-busybox-initramfs.nix {};
  mkModulesClosure = callPackage ./pkgs/mk-modules-closure.nix {};
  aggregateModules = callPackage ./pkgs/aggregate-modules.nix {};

  busybox-static = busybox.override {
    enableStatic = true;
    useMusl = true;
  };
}
