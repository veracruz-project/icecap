{ frameworkTopLevel ? ../framework }:

frameworkTopLevel.override (superArgs: selfTopLevel:
  let
    concreteSuperArgs = superArgs selfTopLevel;
  in
    concreteSuperArgs // {
      nixpkgsArgsFor = crossSystem:
        let
          nixpkgsArgsSuper = concreteSuperArgs.nixpkgsArgsFor crossSystem;
        in
          nixpkgsArgsSuper // {
            overlays = nixpkgsArgsSuper.overlays ++ [
              (import ./overlay.nix)
            ];
          };
    }
)
