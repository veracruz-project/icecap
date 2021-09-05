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
      });

  topLevel = makeOverridableWith lib.id mkTopLevel mkBaseArgs;

in
  topLevel
