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
        kernelArch = "arm64";
        kernelTarget = "Image";
      };
    };
    none-intel.config = "x86_64-none-elf";
    wasi = {
      config = "wasm32-wasi";
      useLLVM = true;
    };
    wasm = {
      config = "wasm32-unknown-unknown"; # TODO or wasm32-unknown-none-unknown
      useLLVM = true;
    };
  };

  baseArgs = {
    overlays = [
      (import ./nix-linux/overlay.nix)
      (import ./overlay)
      (self: super: lib.mapAttrs' (k: lib.nameValuePair "pkgs_${k}") pkgs)
    ];
    config = {
      allowUnfree = true;
    };
  };

  mkPkgs = args: lib.mapAttrs (_: crossSystem:
    import ../nixpkgs ({ inherit crossSystem; } // args)
  ) crossSystems // {
    inherit lib;
  };

  pkgs = makeOverridableWith lib.id mkPkgs baseArgs;

in
  pkgs // {
    # HACK
    inherit (pkgs.none) instances;
  }
