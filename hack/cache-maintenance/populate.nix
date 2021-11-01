with import ../..;

let
  roots = [
    meta.buildTests.all
  ];

in
pkgs.dev.writeText "cache-roots" (toString roots)
