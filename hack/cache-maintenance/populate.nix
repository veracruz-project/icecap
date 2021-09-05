with import ../..;

let
  roots = [
    # HACK
    meta.buildTest
  ];

in
pkgs.dev.writeText "cache-roots" (toString roots)
