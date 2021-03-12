let
  top = import ../nix;
  components = top.none.icecap.configured.virt.icecapFirmware.components;

  size = path: import (top.dev.runCommand "size.nix" {} ''
    stat --format="%s" ${path} > $out
  '');

in with components;
  size loader-elf.min -
    (with config.components;
      size host_vmm.image.min + size host_vm.kernel + size host_vm.dtb +
      size timer_server.image.min + size serial_server.image.min
    )
