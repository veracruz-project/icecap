/*

This is the top-level IceCap Framework attribute set, referred to as `framework`,
or `icecapFramework in` busier scopes. It has the following structure:

{
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

  # Less important attributes, found in `./top-level`
  ...
}

*/

let
  lib = import ../../nixpkgs/lib;

  makeOverridableWith = f: g: x: (g x) // {
    override = x': makeOverridableWith f g (f x' x);
  };

  crossSystems =
    let
      guard = config: if config == framework.pkgs.dev.hostPlatform.config then null else { inherit config; };
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

  baseArgs = selfFramework: {
    config = {};
    nixpkgsArgsFor = crossSystem: {
      inherit crossSystem;
      overlays = [
        (_self: _super: {
          icecapFramework = selfFramework;
        })
        (import ./nix-linux/overlay.nix)
        (import ./overlay)
      ];
      config = {
        allowUnfree = true;
      };
    };
  };

  mkFramework = args: lib.fix (self:
    let
      concreteArgs = args self;
      pkgs = lib.mapAttrs (_: crossSystem:
        import ../../nixpkgs (concreteArgs.nixpkgsArgsFor crossSystem)
      ) crossSystems;
    in {
      inherit lib pkgs;
      inherit (concreteArgs) config;
    } // import ./top-level self);

  framework = makeOverridableWith lib.id mkFramework baseArgs;

in
  framework
