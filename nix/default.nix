let
  frameworkTopLevel = import ./framework;
  hypervisorTopLevel = import ./hypervisor { inherit frameworkTopLevel; };
in
hypervisorTopLevel.lib.fix (self: hypervisorTopLevel // {
    meta = import ./meta self;
})
