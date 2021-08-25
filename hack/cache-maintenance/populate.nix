with import ../..;

let
  roots = [
    # HACK
    buildTest
  ];

in
pkgs.dev.writeText "root" (toString roots)
