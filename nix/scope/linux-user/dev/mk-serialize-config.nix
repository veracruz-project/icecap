{ lib
, buildRustPackageIncrementally
, crateUtils, outerGlobalCrates
, linkFarm, writeText
}:

{ name, type, crate ? null }:

let
  main_rs = writeText "main.rs" ''
    #![feature(type_ascription)]

    use std::marker::PhantomData;

    fn main() -> Result<(), std::io::Error> {
        icecap_config_cli_core::main(PhantomData: PhantomData<${type}>)
    }
  '';
in

buildRustPackageIncrementally rec {
  rootCrate = crateUtils.mkGeneric {
    name = "serialize-${name}-config";
    isBin = true;
    src.store = linkFarm "src" [
      { name = "main.rs"; path = main_rs; }
    ];
    localDependencies = lib.optionals (crate != null) [
      crate
    ] ++ [
      outerGlobalCrates.icecap-config-cli-core
    ];
    dependencies = {
      serde = "*";
      serde_json = "*";
      pinecone = "*";
    };
  };

  layers =  [ [] ] ++ lib.optionals (crate != null) [
    [ crate ]
  ];

  debug = true;
}
