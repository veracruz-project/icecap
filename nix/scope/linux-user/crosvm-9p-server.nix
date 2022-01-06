{ buildRustPackageIncrementally, globalCrates
, pkgconfig, dbus
}:

buildRustPackageIncrementally rec {
  rootCrate = globalCrates.crosvm-9p-server-cli;

  extra = attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ [ pkgconfig ];
    buildInputs = (attrs.buildInputs or []) ++ [ dbus ];

    PKG_CONFIG_ALLOW_CROSS = 1;

    passthru = (attrs.passthru or {}) // {
      exe = rootCrate.name;
    };
  };
}
