{ pkgs, configured }:

let
  components = configured.virt.icecapFirmware.components;

  size = path: import (pkgs.dev.runCommand "size.nix" {} ''
    stat --format="%s" ${path} > $out
  '');

  kb = bytes: import (pkgs.dev.runCommand "size.nix" {
    nativeBuildInputs = [ pkgs.dev.python ];
  } ''
    python -c 'print("\"{}K\"".format(${toString bytes} // 1024))' > $out
  '');

  untrusted = with components.config.components;
    size host_vmm.image.min + size host_vm.kernel + size host_vm.dtb
    + size timer_server.image.min + size serial_server.image.min;

  bytes = size components.loader-elf.min - untrusted;

in kb bytes
