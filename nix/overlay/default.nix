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

  # Increase timeouts for slow environments
  systemd = super.systemd.overrideDerivation (attrs: {
    postPatch = (attrs.postPatch or "") + (let t = "300s"; in ''
      find . '(' -name '*.service' -o -name '*.service.in' ')' -exec sed -i -r \
        -e 's/TimeoutStartSec=[0-9]+s/TimeoutStartSec=${t}/' \
        -e 's/TimeoutStopSec=[0-9]+s/TimeoutStopSec=${t}/' \
        -e 's/TimeoutSec=[0-9]+s/TimeoutSec=${t}/' \
        {} ';'
    '');
  });

  # No X11 libs (see nixpkgs/nixos/modules/config/no-x-libs.nix)
  dbus = super.dbus.override { x11Support = false; };
  gobjectIntrospection = super.gobjectIntrospection.override { x11Support = false; };
  pinentry = super.pinentry_ncurses;
}
