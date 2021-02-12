{ mkInstance
, icecapSrcAbsSplit
, libs, bins, liboutline
, buildIceCapCrateBin, crateUtils, globalCrates
, mkMirageBinary, splitDebug
}:

mkInstance (self: with self; {

  config = {
    components = {
      fault_handler.image = bins.fault-handler.split;
      timer_server.image = bins.timer-server.split;
      serial_server.image = bins.serial-server.split;
      mirage.image = splitDebug "${mirageBinary}/bin/mirage.elf";
    };
  };

  mirageLibrary = callPackage ./mirage.nix {};
  mirageBinary = mkMirageBinary mirageLibrary;

  src = ./cdl;

})
