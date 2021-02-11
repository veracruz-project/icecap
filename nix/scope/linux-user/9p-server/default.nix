{ buildRustPackageIncrementally, globalCrates
, pkgconfig, dbus
}:

with globalCrates;

buildRustPackageIncrementally rec {
  rootCrate = icecap-p9-server-linux-cli;
  layers = [ [] ];

  debug = true;

  PKG_CONFIG_ALLOW_CROSS = 1;

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ dbus ];

  passthru = {
    exe = rootCrate.name;
  };
}
