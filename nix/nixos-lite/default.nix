{ busybox }:

self: with self;

{
  eval = callPackage ./eval.nix {};

  mkExtraUtils = callPackage ./pkgs/mk-extra-utils.nix {};
  mkNixInitramfs = callPackage ./pkgs/mk-nix-initramfs.nix {};

}
