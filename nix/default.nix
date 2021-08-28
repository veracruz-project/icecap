let
  lib = import ../nixpkgs/lib;

  makeOverridableWith = f: g: x: (g x) // {
    override = x': makeOverridableWith f g (f x' x);
  };

  crossSystems = {
    dev = null;
    linux.config = "aarch64-unknown-linux-gnu";
    musl.config = "aarch64-unknown-linux-musl";
    none = {
      config = "aarch64-none-elf"; # TODO or aarch64-unknown-none
      platform = {
        linuxArch = "arm64";
        linux-kernel.target = "Image";
      };
    };
    none-intel.config = "x86_64-none-elf";
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

  mkTargets = args: import ./targets (mkPkgs args);

  targets = makeOverridableWith lib.id mkTargets baseArgs;

in
  # TODO call this file from ./targets instead
  targets
