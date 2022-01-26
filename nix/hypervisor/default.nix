{ framework ? import ../framework }:

let
  inherit (framework) lib;

  frameworkWithOverrides = framework.override (superArgs: selfFramework:
    let
      concreteSuperArgs = superArgs selfFramework;
    in
      concreteSuperArgs // {
        nixpkgsArgsFor = crossSystem:
          let
            superNixpkgsArgs = concreteSuperArgs.nixpkgsArgsFor crossSystem;
          in
            superNixpkgsArgs // {
              overlays = superNixpkgsArgs.overlays ++ [
                (import ./overlay)
              ];
            };
      }
  );
in lib.fix (self: {
  framework = frameworkWithOverrides;
} // import ./top-level self)
