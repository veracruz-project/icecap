{ lib
, pkgs
, system ? builtins.currentSystem
}:

{ modules ? [] }:

let
  baseModule = import ./modules;

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
  modules = [ baseModule ] ++ [ pkgsModule ] ++ modules;
}
