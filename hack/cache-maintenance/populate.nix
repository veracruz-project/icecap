with import ../..;

let
  roots = [
    meta.buildTest
  ];

in
pkgs.dev.writeText "cache-roots" (toString roots)
