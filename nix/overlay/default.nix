self: super: with self;

{
  icecap = makeSplicedScope ../scope {};

  nixosLite = lib.makeScope newScope (callPackage ../nixos-lite {});

  inherit (callPackage ./lib.nix {}) makeSplicedScope makeSplicedScopeOf makeOverridable';

  # Global overrides

  python3 = super.python3.override {
    packageOverrides = callPackage ./python.nix {};
  };

  # Augment QEMU virt machine with a simple timer device model and a simple channel device model
  qemu-base = super.qemu-base.overrideDerivation (attrs: {
    patches = attrs.patches ++ [
      (fetchurl {
        url = "https://github.com/heshamelmatary/qemu-icecap/commit/ddff7b0b034a99040ec4e50026a9839b3fb858ea.patch";
        sha256 = "sha256-h66WG44BimLorWwETstIigcWskNy6Z6VeTkMYX1a8wU=";
      })
    ];
  });

}
