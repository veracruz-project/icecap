let
  lib = import ../nixpkgs/lib;

  makeOverridableWith = f: g: x: (g x) // {
    override = x': makeOverridableWith f g (f x' x);
  };

  crossSystems = {
    dev = null;
    linux.config = "aarch64-unknown-linux-gnu";
    musl.config = "aarch64-unknown-linux-musl";
    none.config = "aarch64-none-elf";
  };

  baseArgs = {
    overlays = [
      (import ./nix-linux/overlay.nix)
      (import ./overlay)
      (self: super: lib.mapAttrs' (k: lib.nameValuePair "pkgs_${k}") basePkgs) # HACK doesn't incorporate overrides
    ];
    config = {
      allowUnfree = true;
    };
  };

  basePkgs = mkPkgs baseArgs;

  mkPkgs = args: lib.mapAttrs (_: crossSystem:
    import ../nixpkgs ({ inherit crossSystem; } // args)
  ) crossSystems // {
    inherit lib;
  };

  pkgs = makeOverridableWith lib.id mkPkgs baseArgs;

in
  pkgs
