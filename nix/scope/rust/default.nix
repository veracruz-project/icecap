{ lib
, fetchFromGitHub
, runCommand
, hostPlatform, targetPlatform
, zlib
, emptyDirectory
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
    version = "nightly";
    date = "2021-08-25";
    sha256 = "sha256-mrVjtmI9w7uvHvlqZ0C7tFWMFKyGXPfnotrPWVyEnl0=";
    components = [ "rustc" "rust-std-${platform}" "cargo" ];
    binaries = [ "rustc" "rustdoc" "cargo" ];
    postInstall = ''
      ln -sv ${zlib}/lib/libz.so{,.1} $out/lib
    '';
  };

  cargoPrebuilt = rustcPrebuilt;

  rustfmtPrebuilt = mkRustPrebuilt rec {
    name = "rustfmt";
    version = "nightly";
    date = "2021-08-25";
    sha256 = "sha256-lTm51x51Hx2/p+MS6wPydo6Uj+VROxy4H8oXbWXNgdU=";
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

  rustTargets = if targetPlatform.config == "aarch64-none-elf" || hostPlatform.config == "aarch64-none-elf" then lib.cleanSource ./targets else emptyDirectory;

  crateUtils = callPackage ./crate-utils.nix {};

}
