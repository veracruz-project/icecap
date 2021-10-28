/*

This is the top-level IceCap attribute set, referred to as topLevel.
It has the following structure:

{

  # Top-level build targets including tests, benchmarks, and demos. See `./meta`.
  meta = ...;

  # A Nixpkgs attribute set for each target system, each augmented with the overlay at `./overlay`.
  # This overlay adds the `.icecap` attribute which holds a scope containing the IceCap expressions.
  # This scope is expressed in `./scope`. For more a description of each target system, see
  # `crossSystems` below.
  pkgs = {
    dev = ...;
    linux = ...;
    musl = ...;
    none = ...;
  };

  # The Nixpkgs library, imported from `../nixpkgs/lib`.
  lib = ...;

}

*/

let
  lib = import ../nixpkgs/lib;

  makeOverridableWith = f: g: x: (g x) // {
    override = x': makeOverridableWith f g (f x' x);
  };

  crossSystems =
    let
      guard = config: if config == topLevel.pkgs.dev.hostPlatform.config then null else { inherit config; };
    in {
      # The development system which hosts the build.
      dev = null;
      # Linux userland on AArch64 with glibc
      linux = guard "aarch64-unknown-linux-gnu";
      # Linux userland on AArch64 with musl
      musl = guard "aarch64-unknown-linux-musl";
      # Bare-metal AArch64
      none = guard "aarch64-none-elf";
    };

  mkBaseArgs = crossSystem: allPkgs: {
    inherit crossSystem;
    overlays = [
      (import ./nix-linux/overlay.nix)
      (import ./overlay)
      (self: super: lib.mapAttrs' (k: lib.nameValuePair "${k}Pkgs") allPkgs)
    ];
    config = {
      allowUnfree = true;
    };
  };

  mkTopLevel = mkArgs:
    let
      pkgs = lib.fix (self: lib.mapAttrs (_: crossSystem:
        import ../nixpkgs (mkArgs crossSystem self)
      ) crossSystems);
    in
      lib.fix (self: {
        inherit lib pkgs;
        meta = import ./meta self;
        inherit (self.meta) export; # HACK
      });

  topLevel = makeOverridableWith lib.id mkTopLevel mkBaseArgs;

in
  topLevel
