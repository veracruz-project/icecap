self: super: with self;

{

  icecap =
    let
      otherSplices = callPackage ({
        pkgsBuildBuild, pkgsBuildHost, pkgsBuildTarget, pkgsHostHost, pkgsTargetTarget
      }: {
        selfBuildBuild = pkgsBuildBuild.icecap;
        selfBuildHost = pkgsBuildHost.icecap;
        selfBuildTarget = pkgsBuildTarget.icecap;
        selfHostHost = pkgsHostHost.icecap;
        selfTargetTarget = pkgsTargetTarget.icecap or {}; # might be missing
      }) {};
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {}) # keep
        (_: {}) # extra
        (self: callPackage ../scope {} self // {
          __dontRecurseWhenSplicing = true;
          inherit otherSplices;
          pkgsBuildHostScope = otherSplices.selfBuildHost;
          pkgsBuildBuildScope = otherSplices.selfBuildBuild;
          pkgsTargetTargetScope = otherSplices.selfTargetTarget;
        })
      ;

  stdenv = rec {
    # Use toolchain without newlib. This is equivalent to crossLibcStdenv
    aarch64-none = super.overrideCC super.stdenv buildPackages.gccCrossStageStatic;
  }.${super.hostPlatform.system} or super.stdenv;

  # Add Python packages needed by seL4 ecosystem
  python3 = super.python3.override {
    packageOverrides = callPackage ./python.nix {};
  };

  # Override QEMU source for ../nix-linux
  qemu-base = super.qemu-base.overrideDerivation (attrs: {
    patches = attrs.patches ++ [
      # Augment qemu -M virt with a simple timer device model and a simple channel device model
      (fetchurl {
        url = "https://github.com/heshamelmatary/qemu-icecap/commit/ddff7b0b034a99040ec4e50026a9839b3fb858ea.patch";
        sha256 = "sha256-h66WG44BimLorWwETstIigcWskNy6Z6VeTkMYX1a8wU=";
      })
    ];
  });

}
