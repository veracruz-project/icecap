with import ../..;

let
  roots = [
    meta.everything.cached
  ];

in
pkgs.dev.writeText "cache-root" (toString roots)
