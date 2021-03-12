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

  extraLinks = sel4test.extraDebugFiles;

  inherit (sel4test) composition;

})
