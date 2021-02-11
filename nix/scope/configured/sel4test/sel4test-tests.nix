{ runCMake, stdenvNonRoot, repos, remoteLibs
, mkFakeConfig
}:

runCMake stdenvNonRoot rec {
  baseName = "sel4test-tests";

  source = repos.rel.sel4test "apps/${baseName}";

  extraPropagatedBuildInputs = with remoteLibs; [
    libsel4allocman
    libsel4vka
    libsel4utils
    libsel4rpc
    libsel4test
    libsel4sync
    libsel4muslcsys
    libsel4testsupport
    libsel4serialserver
  ];

  extraBuildInputs = [
    # TODO circular dependencies upstream
    (mkFakeConfig "sel4test-driver" {
      HAVE_TIMER = "1";
    })
  ];

  extraCFlagsCompile = [
    # TODO circular dependencies upstream
    "-I${repos.rel.sel4test "apps/sel4test-driver"}/include"
  ];

  extraCFlagsLink = [
    # TODO for all binaries?
    "-Wl,-u" "-Wl,__vsyscall_ptr"
  ];

}
