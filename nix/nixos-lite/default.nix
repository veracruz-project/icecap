{ lib, pkgs }:

{

  eval = { modules }:

    let
      metaModule = {
        config = {
          _module.args.pkgs = lib.mkForce pkgs;
          _module.check = true;
        };
      };

      baseModule = import ./modules;

    in
      lib.evalModules {
        modules = [ metaModule baseModule ] ++ modules;
      };

}
