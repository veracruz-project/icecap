{ lib }:

rec {

  # Like to `lib.callPackageWith`, except without `lib.makeOverridable`.
  callWith = autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
    in f (auto // args);

  # Like `lib.makeOverridable`, except it adds an orthogonal dimension of overrideablility
  # accessible at `.override'`.
  makeOverridable' = f: origArgs:
    let
      overrideWith = newArgs: origArgs // (if lib.isFunction newArgs then newArgs origArgs else newArgs);
    in f origArgs // {
      override' = newArgs: makeOverridable' f (overrideWith newArgs);
    };

}
