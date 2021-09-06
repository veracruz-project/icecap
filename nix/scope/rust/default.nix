{ lib, hostPlatform, targetPlatform
, devPkgs, linuxPkgs, muslPkgs, nonePkgs
, zlib
}:

self: with self;

let

  mkPrebuilt = callPackage ./prebuilt {};

in {

  nixToToml = callPackage ./nix-to-toml {};

  rustcPrebuilt = mkPrebuilt rec {
    name = "rust";
    version = "nightly";
    date = "2021-08-25";
    sha256 = "sha256-mrVjtmI9w7uvHvlqZ0C7tFWMFKyGXPfnotrPWVyEnl0=";
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
    sha256 = "sha256-lTm51x51Hx2/p+MS6wPydo6Uj+VROxy4H8oXbWXNgdU=";
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

  # TODO tune
  rustTargets = icecapSrc.clean ./targets;

  rustc0 = callPackage ./rustc.nix {
    rustc = pkgsBuildHostScope.rustcPrebuilt;
    cargo = pkgsBuildHostScope.cargoPrebuilt;
    rustfmt = pkgsBuildHostScope.rustfmtPrebuilt;
    targets = [ devPkgs linuxPkgs muslPkgs nonePkgs ];
  };

  # HACK
  rustc = devPkgs.icecap.rustc0;

  cargo0 = callPackage ./in-tree-component.nix {
    rustc = pkgsBuildHostScope.rustc0;
    cargo = pkgsBuildHostScope.cargoPrebuilt;
  } {
    package = "cargo";
  };

  cargo = cargo0;

  rustfmt = (callPackage ./in-tree-component.nix {} {
    package = "rustfmt-nightly";
  }).overrideAttrs (attrs: {
    RUSTC_BOOTSTRAP = 1;
  });

  # rustfmt = rustfmtPrebuilt;

  fetchCargo = callPackage ./fetch-cargo.nix {};
  fetchCargoBootstrap = callPackage ./fetch-cargo.nix {
    cargo = pkgsBuildHostScope.cargoPrebuilt;
  };
  fetchCrates = callPackage ./fetch-crates.nix {};
  cargoLockToNix = callPackage ./cargo-lock-to-nix {};

  fetchCratesIOTarball = callPackage ./fetch-crate/fetch-crates-io-tarball.nix {};
  unpackCrateTarball = callPackage ./fetch-crate/unpack-tarball.nix {};
  fetchGitCrate = callPackage ./fetch-crate/fetch-git.nix {};
  fetchCratesIOCrate = args: unpackCrateTarball (fetchCratesIOTarball args);

  cratesIOIndexCache = callPackage ./crates-io-index-cache.nix {};
  generateLockfile = rootCrate: generateLockfileInternal { inherit rootCrate; };
  generateLockfileInternal = callPackage ./generate-lockfile.nix {};

  buildRustPackage = callPackage ./build-rust-package.nix {};
  buildRustPackageIncrementally = callPackage ./build-rust-package-incrementally.nix {};
  crateUtils = callPackage ./crate-utils.nix {};

  bindgen = callPackage ./bindgen {};

}
