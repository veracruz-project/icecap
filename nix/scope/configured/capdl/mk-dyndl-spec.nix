{ runCommand
, mkCpioObj
, capdl-loader-lib
, capdl-tool
, object-sizes
, serialize-dyndl-spec
}:

{ cdl, root }:

let
  json = runCommand "dyndl_spec.json" {
    nativeBuildInputs = [
      capdl-tool
    ];
  } ''
    parse-capDL --code-dynamic-alloc --object-sizes=${object-sizes} --dyndl=$out ${cdl}
  '';

  bin = runCommand "dyndl_spec.bin" {
    nativeBuildInputs = [
      serialize-dyndl-spec
    ];
    passthru = {
      inherit json;
    };
  } ''
    serialize-dyndl-spec ${root} < ${json} > $out
  '';
in
  bin
