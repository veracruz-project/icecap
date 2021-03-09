{ mkInstance
, compose
, icecapSrcAbsSplit
, bins, liboutline
, buildIceCapCrateBin, crateUtils, globalCrates
}:

mkInstance (self: with self; {

  composition = compose {
    src = ./cdl;
    config = {
      components = {
        test.image = test.split;
        fault_handler.image = bins.fault-handler.split;
        timer_server.image = bins.timer-server.split;
        serial_server.image = bins.serial-server.split;
      };
    };
  };

  test = buildIceCapCrateBin {
    rootCrate = crateUtils.mkGeneric {
      name = "test";
      src = icecapSrcAbsSplit ./test;
      isBin = true;
      localDependencies = with globalCrates; [
        icecap-std
        icecap-start-generic
      ];
      dependencies = {
        serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
      };
    };
    buildInputs = [
      liboutline
    ];
  };

})
