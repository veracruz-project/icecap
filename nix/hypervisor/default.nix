{ framework ? ../framework }:

let
  inherit (framework) lib;

  frameworkWithOverrides = framework.override (superArgs: selfTopLevel:
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
                (import ./overlay)
              ];
            };
      }
  );
in lib.fix (self: {
  framework = frameworkWithOverrides;
  meta = import ./meta self;
})
