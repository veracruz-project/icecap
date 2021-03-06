{ runCommand
, capdl-tool
, dyndl-serialize-spec
, object-sizes
}:

{ cdl, root, extraPassthru ? {} }:

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
    } // extraPassthru;
  } ''
    dyndl-serialize-spec ${root} < ${json} > $out
  '';
in
  bin
