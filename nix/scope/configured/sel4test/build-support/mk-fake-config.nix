{ lib, runCommandCC, writeText }:

name: config:

let
  h = writeText "gen_config.h" ''
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      #define CONFIG_${k} ${v}
    '') config)}
  '';

in
runCommandCC "${name}_Config" {} ''
  mkdir -p $out/lib $out/include/${name}
  ln -s ${h} $out/include/${name}/gen_config.h
  $AR r $out/lib/lib${name}_Config.a
''
