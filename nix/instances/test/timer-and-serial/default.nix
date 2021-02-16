{ mkInstance
, icecapSrcAbsSplit
, bins, liboutline
, buildIceCapCrateBin, crateUtils, globalCrates
}:

mkInstance (self: with self; {

  test = buildIceCapCrateBin {
    rootCrate = crateUtils.mkGeneric {
      name = "test";
      src = icecapSrcAbsSplit ./test;
      isBin = true;
      localDependencies = [
        globalCrates.icecap-std
      ];
      dependencies = {
        serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
      };
    };
    buildInputs = [
      liboutline
    ];
  };

  config = {
    components = {
      test.image = test.split;
      fault_handler.image = bins.fault-handler.split;
      timer_server.image = bins.timer-server.split;
      serial_server.image = bins.serial-server.split;
    };
  };

  src = ./cdl;

})
