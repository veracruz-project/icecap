{ lib
, pkgs
, system ? builtins.currentSystem
}:

let
  mk = baseModules:
    { modules ? [] }:

    let
      pkgsModule = {
        config = {
          _module.args.pkgs = lib.mkIf (pkgs != null) (lib.mkForce pkgs);
          _module.check = true;
          # TODO
          # nixpkgs.system = lib.mkDefault system;
        };
      };

    in
      lib.evalModules {
        modules = baseModules ++ [ pkgsModule ] ++ modules;
      };

in lib.mapAttrs (_: mk) (import ./modules)
