{ mkRun
, sel4test
, repos, kernel
}:

# let
#   kernel_ = kernel;
# in let
#   kernel = kernel_.override' (attrs: {
#     source = attrs.source.override' (attrs': {
#       src = with repos; maybeClean local.seL4;
#     });
#   });
# in

self: with self;

{

  run = mkRun {
    inherit kernel;
    payload = "${sel4test.sel4test-driver}/bin/sel4test-driver";
    extraLinks = {
      "tests.elf" = "${sel4test.sel4test-tests}/bin/sel4test-tests";
    };
  };

}
