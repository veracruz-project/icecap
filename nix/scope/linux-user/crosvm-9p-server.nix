{ buildRustPackageIncrementally, globalCrates
}:

buildRustPackageIncrementally rec {
  rootCrate = globalCrates.crosvm-9p-server-cli;

  extra = attrs: {
    passthru = (attrs.passthru or {}) // {
      exe = rootCrate.name;
    };
  };
}
