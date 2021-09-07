{ buildRustPackageIncrementally, outerGlobalCrates
, pkgconfig, dbus
}:

buildRustPackageIncrementally rec {
  rootCrate = outerGlobalCrates.crosvm-9p-server-cli;
  layers = [ [] ];

  extra = attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [ pkgconfig ];
    buildInputs = (attrs.buildInputs or []) ++ [ dbus ];

    PKG_CONFIG_ALLOW_CROSS = 1;

    passthru = (attrs.passthru or {}) // {
      exe = rootCrate.name;
    };
  };
}
