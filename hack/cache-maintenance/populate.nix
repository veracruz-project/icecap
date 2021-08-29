with import ../..;

let
  roots = [
    # HACK
    meta.buildTest
  ];

in
pkgs.dev.writeText "root" (toString roots)
