{ runCommand, python3Packages }:

expr:

builtins.fromJSON (builtins.readFile (runCommand "sorted.nix" {
  nativeBuildInputs = [
    python3Packages.toposort
  ];
  json = builtins.toJSON expr;
  passAsFile = [ "json" ];
} ''
  python ${./helper.py} < $jsonPath > $out
''))
