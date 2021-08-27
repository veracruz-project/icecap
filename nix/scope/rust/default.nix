{ lib
, fetchFromGitHub
, runCommand
, hostPlatform, targetPlatform
}:

let
  platform = "x86_64-unknown-linux-gnu";
in

self: with self; {

  nixToToml = callPackage ./nix-to-toml {};

  buildRustPackage = callPackage ./build-rust-package.nix {};
  buildRustPackageIncrementally = callPackage ./build-rust-package-incrementally.nix {};

  mkRustPrebuilt = callPackage ./prebuilt {};

  rustcPrebuilt = mkRustPrebuilt rec {
    name = "rust";
    version = "1.44.0";
    sha256 = "sha256-6qNCcbSsTSwoGDERfU0zXu0LN/56NEd9mFWm8dkwpiQ=";
    components = [ "rustc" "rust-std-${platform}" "cargo" ];
    binaries = [ "rustc" "rustdoc" "cargo" ];
  };

  cargoPrebuilt = rustcPrebuilt;

  rustfmtPrebuilt = mkRustPrebuilt rec {
    name = "rustfmt";
    version = "nightly";
    date = "2020-06-09";
    sha256 = "sha256-TlmeAcuOeodwVhMmY5iqnx777BMLFzcipmZdg9+Y08o=";
    components = [ "rustfmt-preview" ];
    binaries = [ "rustfmt" ];
  };

  rustc0 = callPackage ./rustc.nix rec {
    rustc = pkgsBuildHostScope.rustcPrebuilt;
    cargo = pkgsBuildHostScope.cargoPrebuilt;
    rustfmt = pkgsBuildHostScope.rustfmtPrebuilt;
  };

  rustc = rustc0;

  cargo0 = callPackage ./cargo.nix (with pkgsBuildHostScope; {
    rustc = rustc0;
    cargo = cargoPrebuilt;
  });

  cargo = cargo0;

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

  # NOTE broken
  # rustfmt = callPackage ./rustfmt.nix {};
  rustfmt = rustfmtPrebuilt;

  bindgen = callPackage ./bindgen {};

  rustTargets = lib.cleanSource ./targets;

  crateUtils = callPackage ./crate-utils.nix {};

}
