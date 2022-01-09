{ lib, hostPlatform, targetPlatform
, zlib
}:

self: with self;

let

  mkPrebuilt = callPackage ./prebuilt.nix {};

in {

  nixToToml = callPackage ./nix-to-toml {};

  rustcPrebuilt = mkPrebuilt rec {
    name = "rust";
    version = "nightly";
    date = "2021-08-25";
    sha256 = {
      x86_64-unknown-linux-gnu = "sha256-mrVjtmI9w7uvHvlqZ0C7tFWMFKyGXPfnotrPWVyEnl0=";
      aarch64-unknown-linux-gnu = "sha256-88KRQrHg4qynlkUzAZo831iJo5jRyOUJBr71rFbDurc=";
    };
    components = [ "rustc" "rust-std-${hostPlatform.config}" "cargo" ];
    binaries = [ "rustc" "rustdoc" "cargo" ];
    postInstall = ''
      ln -sv ${zlib}/lib/libz.so{,.1} $out/lib
    '';
  };

  cargoPrebuilt = rustcPrebuilt;

  rustfmtPrebuilt = mkPrebuilt rec {
    name = "rustfmt";
    version = "nightly";
    date = "2021-08-25";
    sha256 = {
      x86_64-unknown-linux-gnu = "sha256-lTm51x51Hx2/p+MS6wPydo6Uj+VROxy4H8oXbWXNgdU=";
      aarch64-unknown-linux-gnu = "sha256-CN4m2EI5CGDXDT43I0N170sY9AEqYeTxePOedLTQuv4=";
    };
    components = [ "rustfmt-preview" ];
    binaries = [ "rustfmt" ];
  };

  rustSource = builtins.fetchGit {
    url = "https://github.com/rust-lang/rust.git";
    ref = "master";
    rev = "b03ccace573bb91e27625c190a0f7807045a1012";
    submodules = true;
  };

  rustVendoredSources = fetchCargoBootstrap {
    src = rustSource;
    sha256 = "sha256-Z3XCOhvOVJ6DT+XpS2hAHubFwgvnaUBRjfaBa8HJ0jo=";
  };

  icecapRustTargetName = arch: "${arch}-icecap";

  rustTargetName = if hostPlatform.isNone then icecapRustTargetName hostPlatform.parsed.cpu.name else hostPlatform.config;

  # TODO tune
  rustTargets = icecapSrc.relative "rust/support/targets";

  rustc0 = callPackage ./rustc.nix {
    rustc = otherSplices.selfBuildHost.rustcPrebuilt;
    cargo = otherSplices.selfBuildHost.cargoPrebuilt;
    rustfmt = otherSplices.selfBuildHost.rustfmtPrebuilt;
    targets = [ devPkgs linuxPkgs muslPkgs nonePkgs ];
  };

  # HACK
  rustc = devPkgs.icecap.rustc0;

  cargo0 = callPackage ./in-tree-component.nix {
    rustc = otherSplices.selfBuildHost.rustc0;
    cargo = otherSplices.selfBuildHost.cargoPrebuilt;
  } {
    package = "cargo";
  };

  cargo = cargo0;

  # rustfmt = (callPackage ./in-tree-component.nix {} {
  #   package = "rustfmt-nightly";
  # }).overrideAttrs (attrs: {
  #   RUSTC_BOOTSTRAP = 1;
  # });

  rustfmt = rustfmtPrebuilt;

  bindgen = callPackage ./bindgen.nix {};

  fetchCargo = callPackage ./fetch-cargo.nix {};
  fetchCargoBootstrap = callPackage ./fetch-cargo.nix {
    cargo = otherSplices.selfBuildHost.cargoPrebuilt;
  };
  fetchCrates = callPackage ./fetch-crates.nix {};
  cargoLockToNix = callPackage ./cargo-lock-to-nix {};

  fetchCratesIOTarball = callPackage ./fetch-crate/fetch-crates-io-tarball.nix {};
  unpackCrateTarball = callPackage ./fetch-crate/unpack-tarball.nix {};
  fetchGitCrate = callPackage ./fetch-crate/fetch-git.nix {};
  fetchCratesIOCrate = args: unpackCrateTarball (fetchCratesIOTarball args);

  cratesIOIndexCache = callPackage ./crates-io-index-cache.nix {};
  generateLockfile = rootCrates: generateLockfileInternal { inherit rootCrates; };
  generateLockfileInternal = callPackage ./generate-lockfile.nix {};

  buildRustPackage = callPackage ./build-rust-package.nix {};
  buildRustPackageIncrementally = callPackage ./build-rust-package-incrementally.nix {};
  crateUtils = callPackage ./crate-utils.nix {};

}
