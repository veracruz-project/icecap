{ lib, pkgs }:

let
  components = pkgs.none.icecap.configured.virt.icecapFirmware.components;

  size = path: import (pkgs.dev.runCommand "size.nix" {} ''
    stat --format="%s" ${path} > $out
  '');

  kb = bytes: import (pkgs.dev.runCommand "size.nix" {
    nativeBuildInputs = [ pkgs.dev.python ];
  } ''
    python -c 'print("\"{}K\"".format(${toString bytes} // 1024))' > $out
  '');

  sum = lib.foldl' (x: y: x + y) 0;

  untrusted = with components.config.components; sum (map size [
    host_vmm.image.min
    host_vm.kernel
    host_vm.dtb
    benchmark_server.image.min

    # TODO should these count?
    # timer_server.image.min
    # serial_server.image.min
  ]);

  bytes = size components.loader-elf.min - untrusted;

in kb bytes
