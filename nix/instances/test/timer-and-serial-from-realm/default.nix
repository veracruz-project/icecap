{ mkInstance
, icecapSrcAbsSplit
, buildIceCapCrateBin, crateUtils, globalCrates
, bins, liboutline
, mkIceDL
, mkDynDLSpec
, kernel, repos
}:

mkInstance (self: with self; {

  test = buildIceCapCrateBin {
    rootCrate = crateUtils.mkGeneric {
      name = "test";
      src = icecapSrcAbsSplit ./test;
      isBin = true;
      localDependencies = with globalCrates; [
        icecap-std
      ];
      dependencies = {
        serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
      };
    };
    extraLayers = [ [ "icecap-std" ] ];
    buildInputs = with libs; [
      liboutline
    ];
  };

  config = {
    components = {
      fault_handler.image = bins.fault-handler.split;
      timer_server.image = bins.timer-server.split;
      serial_server.image = bins.serial-server.split;
      caput.image = bins.caput.split;
      caput.spec = spec;
    };
  };

  ddl = mkIceDL {
    src = ./ddl;
    config = {
      components = {
        test.image = test.split;
      };
    };
  };

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
  };

  src = ./cdl;

  # kernel = kernel.override' (attrs: {
  #   source = attrs.source.override' (attrs': {
  #     src = with repos; local.seL4;
  #   });
  # });

})
