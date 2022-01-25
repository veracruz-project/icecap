{ lib, newScope
, fetchFromGitHub
, callPackage
, buildDunePackage, ocamlfind

# TODO abstract
, stdenvMirage
}:

let

  buildJanePackage = { pname, version ? "0.12.0", sha256, ... } @ args:
    buildDunePackage (args // {
      inherit version;
      src = fetchFromGitHub {
        owner = "janestreet";
        repo = pname;
        rev = "v${version}";
        sha256 = sha256;
      };
    });

    standard = callPackage ./standard.nix {
      inherit buildJanePackage;
    };

in

# TODO weigh performance impact of spicing this scope against its benefits
lib.makeScope newScope (self: standard self // (let inherit (self) callPackage; in {

  # TODO ensure this scope is not spliced within parent scope
  # __icecap_splice = false;

  # TODO abstract
  stdenv = stdenvMirage;

  findlib = ocamlfind;

  topkg = callPackage ./nonstandard/topkg {};
  num = callPackage ./nonstandard/num {};
  seq = callPackage ./nonstandard/seq {};
  ppx_tools = callPackage ./nonstandard/ppx_tools {};
  ocamlgraph = callPackage ./nonstandard/ocamlgraph {};

}))
