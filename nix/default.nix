let
  frameworkTopLevel = import ./framework;
in
frameworkTopLevel.lib.fix (self: frameworkTopLevel // {
    meta = import ./meta self;
})
