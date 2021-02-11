{ runCommand, python3Packages }:

expr:

runCommand "x.toml" {
  nativeBuildInputs = [
    python3Packages.toml
  ];
  json = builtins.toJSON expr;
  passAsFile = [ "json" ];
} ''
  python ${./helper.py} < $jsonPath > $out
''
