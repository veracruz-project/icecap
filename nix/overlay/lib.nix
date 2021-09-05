{ lib, pkgsHostTarget }:

with lib;

rec {

  makeSplicedScope = makeSplicedScopeOf pkgsHostTarget;

  getPkgSets = attrs: {
    inherit (attrs)
      pkgsBuildBuild pkgsBuildHost pkgsBuildTarget
      pkgsHostHost pkgsHostTarget
      pkgsTargetTarget;
  };

  splice =
    { pkgsBuildBuild, pkgsBuildHost, pkgsBuildTarget
    , pkgsHostHost, pkgsHostTarget
    , pkgsTargetTarget
    }:
    let
      spliceAttr = name: value:
        let
          valueBuildBuild = pkgsBuildBuild.${name} or {};
          valueBuildHost = pkgsBuildHost.${name} or {};
          valueBuildTarget = pkgsBuildTarget.${name} or {};
          valueHostHost = throw "`valueHostHost` unimplemented: pass manually rather than relying on splice.";
          valueHostTarget = pkgsHostTarget.${name} or {};
          valueTargetTarget = pkgsTargetTarget.${name} or {};
          augmentedValue = value
            // (lib.optionalAttrs (pkgsBuildHost ? ${name}) { nativeDrv = valueBuildHost; })
            // (lib.optionalAttrs (pkgsHostTarget ? ${name}) { crossDrv = valueHostTarget; })
            // {
              __spliced =
                   (lib.optionalAttrs (pkgsBuildBuild ? ${name}) { buildBuild = valueBuildBuild; })
                // (lib.optionalAttrs (pkgsBuildTarget ? ${name}) { buildTarget = valueBuildTarget; })
                // { hostHost = valueHostHost; }
                // (lib.optionalAttrs (pkgsTargetTarget ? ${name}) { targetTarget = valueTargetTarget; });
            };
          # Get the set of outputs of a derivation. If one derivation fails to evaluate we
          # don't want to diverge the entire splice, so we fall back on {}
          tryGetOutputs = value':
            let inherit (builtins.tryEval value') success value'';
            in lib.optionalAttrs success (getOutputs value'');
          getOutputs = value': lib.genAttrs
            (value'.outputs or (lib.optional (value' ? out) "out"))
            (output: value'.${output});
        in if !(lib.isDerivation value) then value else augmentedValue // splice {
          pkgsBuildBuild = tryGetOutputs valueBuildBuild;
          pkgsBuildHost = tryGetOutputs valueBuildHost;
          pkgsBuildTarget = tryGetOutputs valueBuildTarget;
          pkgsHostHost = tryGetOutputs valueHostHost;
          pkgsHostTarget = getOutputs valueHostTarget;
          pkgsTargetTarget = tryGetOutputs valueTargetTarget;
        };
    in
      mapAttrs spliceAttr pkgsHostTarget;

  makeSplicedScopeOf = pkgSet: f_: args:
    let
      f = pkgSet.callPackage f_ args;

      pkgSets = getPkgSets pkgSet;

      scopes = lib.mapAttrs (k: pkgSet':
        if k == "pkgsHostTarget" then self else
        lib.optionalAttrs (lib.hasAttr "newScope" pkgSet') (makeSplicedScopeOf pkgSet' f_ args) # HACK
      ) pkgSets;

      nextPkgSets = lib.mapAttrs (k: pkgSet':
        pkgSet' // scopes.${k}
      ) pkgSets;

      nextScopes = lib.mapAttrs' (k: pkgSet': {
        name = "${k}Scope";
        value = makeSplicedScopeOf pkgSet' f_ args;
      }) pkgSets;

      splicedAddition = if (pkgSets.pkgsHostTarget.adjacentPackages == null) then self else splice (
        lib.mapAttrs (k: pkgSet':
          if k == "pkgsHostTarget" then self else
          lib.optionalAttrs (lib.hasAttr "newScope" pkgSet') (let scope = makeSplicedScopeOf pkgSet' f_ args; in scope.packages scope) # HACK
        ) pkgSets
      );

      meta = {
        callPackage = self.newScope {};
        callPackages = null; # unimplemented, shadow to avoid accidental call
        packages = f;
        makeSplicedScope = makeSplicedScopeOf self.pkgsHostTarget;
        newScope = scope: pkgSet.newScope (splicedAddition // meta // nextPkgSets // nextScopes // scope);
      };

      self = f self // meta // nextPkgSets // nextScopes;

    in
      self;

  makeOverridable' = f: origArgs:
    let
      overrideWith = newArgs: origArgs // (if lib.isFunction newArgs then newArgs origArgs else newArgs);
    in f origArgs // {
      override' = newArgs: makeOverridable' f (overrideWith newArgs);
    };

}
