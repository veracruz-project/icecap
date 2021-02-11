{ lib, writeScript, runCommand, buildPackages, elfloader, kernel
, virtUtils
, runPkgs
, icecapExtraConfig
, show-backtrace
}:

let
  kernel_ = kernel;
in

let
  basicScript = { kernel, extraArgs ? [] }:
    writeScript "run.sh" (with runPkgs; with virtUtils; ''
      #!${runtimeShell}
      debug=
      if [ "$1" = "d" ]; then
        debug="${join debugArgs}"
      fi
      exec ${cmdPrefix} \
        -d unimp,guest_errors \
        ${join extraArgs} \
        $debug \
        -kernel ${kernel}
    '');

in

{ payload, extraLinks ? {}, kernel ? kernel_ }:

let

  image = elfloader {
    app-elf = payload;
    inherit kernel;
  };

  run = basicScript {
    kernel = image.elf;
  };

  links = {
    inherit run;
    "image.elf" = image.elf;
    "kernel.elf" = image.kernel-elf;
    "kernel.dtb" = image.kernel-dtb;
    "app.elf" = image.app-elf;
    "show-backtrace" = "${show-backtrace.nativeDrv}/bin/show-backtrace";
  } // extraLinks;

in
runCommand "run" {
  passthru = {
    inherit image;
  };
} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    ln -s ${v} $out/${k}
  '') links)}
''
