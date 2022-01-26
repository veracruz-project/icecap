{ lib, pkgs }:

let
  attrs = pkgs.none.icecap.configured.virt.icecapFirmware.attrs;

  whole = [
    attrs.loader-elf.min
  ];

  untrusted = with attrs.cdl.config.components; [
    host_vmm.image.min
    host_vm.kernel
    host_vm.dtb
    timer_server.image.min
    serial_server.image.min
    benchmark_server.image.min
  ];

  input = {
    inherit whole untrusted;
  };

in
pkgs.dev.runCommand "tcb-size.txt" {
  nativeBuildInputs = [
    pkgs.dev.python3
  ];
  json = builtins.toJSON input;
  passAsFile = [ "json" ];
} ''
  python ${./helper.py} < $jsonPath > $out
''
