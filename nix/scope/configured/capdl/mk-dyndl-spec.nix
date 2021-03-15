{ runCommand
, mkCpioObj
, capdl-loader-lib
, capdl-tool
, object-sizes
, dyndl-serialize-spec
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
      dyndl-serialize-spec
    ];
    passthru = {
      inherit json;
    };
  } ''
    dyndl-serialize-spec ${root} < ${json} > $out
  '';
in
  bin
