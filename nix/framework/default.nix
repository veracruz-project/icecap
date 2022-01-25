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

  # Arbitrary global config for use anywhere in the build system (currently unused)
  config = ...;

  # Function to override arguments to `mkTopLevel`.
  # See `baseArgs :: TopLevel -> Args` for the base arguments.
  override :: ((TopLevel -> Args) -> (TopLevel -> Args)) -> TopLevel
  override = f: ...;

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

  baseArgs = selfTopLevel: {
    config = {};
    nixpkgsArgsFor = crossSystem: {
      inherit crossSystem;
      overlays = [
        (_self: _super: {
          icecapTopLevel = selfTopLevel;
        })
        (import ./nix-linux/overlay.nix)
        (import ./overlay)
      ];
      config = {
        allowUnfree = true;
      };
    };
  };

  mkTopLevel = args: lib.fix (self:
    let
      concreteArgs = args self;
      pkgs = lib.mapAttrs (_: crossSystem:
        import ../nixpkgs (concreteArgs.nixpkgsArgsFor crossSystem)
      ) crossSystems;
    in {
      inherit lib pkgs;
      inherit (concreteArgs) config;
      meta = import ./meta self;
    });

  topLevel = makeOverridableWith lib.id mkTopLevel baseArgs;

in
  topLevel
