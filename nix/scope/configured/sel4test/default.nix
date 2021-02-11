{ stdenvToken, mkStdenv
}:

self: with self;

rec {

  runCMake = callPackage ./build-support/run-cmake.nix {};
  runCMakeToken = runCMake stdenvToken;
  mkCMakeTop = callPackage ./build-support/mk-cmake-top.nix {};
  mkFakeConfig = callPackage ./build-support/mk-fake-config.nix {};
  aggretageConfigUtils = callPackage ./build-support/aggregate-config-utils.nix {};

  stdenvNonRoot = mkStdenv (callPackage ./stdenv/non-root.nix {});

  stdenvRoot = (mkStdenv (callPackage ./stdenv/root.nix {
    inherit libsel4runtime;
  })).override (drv: {
    extraAttrs = drv.extraAttrs // {
      isRoot = true;
    };
  });

  libsel4runtime = callPackage ./libsel4runtime.nix {};

  remoteLibs = callPackage ./remote-libs.nix {};

  sel4test-tests = callPackage ./sel4test-tests.nix {};
  sel4test-driver = callPackage ./sel4test-driver.nix {};

  nanopbExternal = callPackage ./nanopb {};

}
