{ buildRustPackageIncrementally, outerGlobalCrates
, pkgconfig, dbus
}:

with outerGlobalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-p9-server-linux-cli;
  layers = [ [] ];

  debug = true;

  extraArgs = {
    PKG_CONFIG_ALLOW_CROSS = 1;

    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ dbus ];

    passthru = {
      exe = rootCrate.name;
    };
  };
}
