self: with self;

let
  call = framework.pkgs.dev.icecap.callWith (self // {
    inherit (framework) lib pkgs;
  });

in {

  everything = call ./everything.nix {};

  instances = call ./instances {};
  inherit (instances) tests benchmarks hacking;

  automatedTests = call ./automated-tests {};

  tcbSize = call ./tcb-size {};

}
