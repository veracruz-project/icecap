{ framework, meta } @ hypervisorTopLevel:

let
  call = framework.pkgs.dev.icecap.callWith (hypervisorTopLevel // meta // {
    inherit (framework) lib pkgs;
  });

in
rec {

  everything = call ./everything.nix {};

  instances = call ./instances {};
  inherit (instances) tests benchmarks hacking;

  automatedTests = call ./automated-tests {};

  tcbSize = call ./tcb-size {};

}
