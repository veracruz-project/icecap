{ mkInstance
, compose, stripElfSplit
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

mkInstance (self: with self; {

  allDebugFiles = false;

  extraLinks = {
    "tests.elf" = "${sel4test.sel4test-tests}/bin/sel4test-tests";
  };

  composition = compose {
    app-elf = stripElfSplit "${sel4test.sel4test-driver}/bin/sel4test-driver";
  };

})
