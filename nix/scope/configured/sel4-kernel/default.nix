{ lib, stdenv, writeText, runCommand, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, stdenvBoot, icecapExternalSrc, elfUtils

, selectIceCapPlat
, deviceTreeConfigured
, cmakeConfig
}:

{ source ? icecapExternalSrc.seL4 }:

let

  patchedSource = stdenv.mkDerivation {
    name = "sel4-kernel-source";
    src = source;
    nativeBuildInputs = [ python3 ];

    phases = [ "unpackPhase" "patchPhase" "installPhase" ];

    postPatch = ''
      # patchShebangs can't handle env -S
      rm configs/*_verified.cmake

      patchShebangs --build .

      cp ${deviceTreeConfigured.seL4} tools/dts/${selectIceCapPlat {
        # The alignment of these names is a coincidence
        rpi4 = "rpi4";
        virt = "virt";
      }}.dts
    '';

    installPhase = ''
      here=$(pwd)
      cd $NIX_BUILD_TOP
      mv $here $out
    '';
  };

  configPrefixes = [
    "Kernel"
    "LibSel4"
    "HardwareDebugAPI"
  ];

  extraConfig = ''
    include(${icecapExternalSrc.seL4}/configs/seL4Config.cmake)
  '';

  cacheScript = writeText "config.cmake" ''
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      set(${k} ${v.value} CACHE ${v.type} "")
    '') (filterInitConfig cmakeConfig configPrefixes))}

    ${extraConfig}
  '';

  filterInitConfig = with lib;
    all: prefixes: filterAttrs (k: v: any (prefix: hasPrefix prefix k) prefixes) all;

in
lib.fix (self: stdenvBoot.mkDerivation rec {
  name = "sel4";

  nativeBuildInputs = [
    cmake ninja rsync
    dtc libxml2
    python3Packages.sel4-deps
  ];

  phases = [
    "configurePhase" "buildPhase" "installPhase"
  ];

  cmakeDir = patchedSource;

  # TODO
  # cmakeBuildType = "Debug";

  cmakeFlags = [
    "-G" "Ninja"
    "-C" cacheScript
    "-DCROSS_COMPILER_PREFIX=${stdenvBoot.cc.targetPrefix}"
    "-DCMAKE_TOOLCHAIN_FILE=${patchedSource}/gcc.cmake"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
  ];

  buildPhase = ''
    ninja all kernel.elf sel4
  '';

  postInstall = ''
    mv $out/libsel4/include $out

    mv $out/bin $out/boot
    cp kernel.dtb $out/boot

    install -D -t $out/lib libsel4/libsel4.a
    install -D -t $out/sel4-aux gen_headers/plat/machine/platform_gen.yaml

    # HACK for access to generated source files during debugging
    mkdir -p $out/debug-aux/src/libsel4
    cp -r gen* autoconf $out/debug-aux/src
    cp -r libsel4/gen* libsel4/autoconf libsel4/*include $out/debug-aux/src/libsel4
    mv $out/libsel4/src $out/debug-aux/libsel4-src
    rmdir $out/libsel4

    # HACK export and propagate config in generic and CMake formats

    mkdir -p $out/sel4-config

    sed -n 's,^\([A-Za-z0-9][^:]*\):\([^=]*\)=\(.*\)$,\1:\2=\3,p' CMakeCache.txt \
      | grep -e '$.^' ${lib.concatMapStringsSep " " (prefix: "-e ^${prefix}") configPrefixes} \
      | sort \
      > $out/sel4-config/kernel.txt

    sed 's/^\([^:]*\):\([^=]*\)=\(.*\)$/set(\1 "\3" CACHE \2 "")/' $out/sel4-config/kernel.txt \
      > $out/sel4-config/kernel.cmake

    cat ${writeText "x" extraConfig} >> $out/sel4-config/kernel.cmake

    # TODO
    $AR r $out/lib/libsel4_autoconf.a
  '';

  passthru = {
    inherit patchedSource;
    dtb = "${self}/boot/kernel.dtb";
    elf = elfUtils.split "${self}/boot/kernel.elf";
  };

})
