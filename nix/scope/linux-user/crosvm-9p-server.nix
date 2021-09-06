{ buildRustPackageIncrementally, outerGlobalCrates
, pkgconfig, dbus
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.crosvm-9p-server-cli;
  layers = [ [] ];

  extraArgs = {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ dbus ];

    PKG_CONFIG_ALLOW_CROSS = 1;

    passthru = {
      exe = rootCrate.name;
    };
  };
}
