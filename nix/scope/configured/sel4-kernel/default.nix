{ lib, writeText, runCommand, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, dtb-helpers
, platUtils, raspios

, stdenv, stdenvBoot, seL4EcosystemRepos, makeOverridable'

, cmakeConfig
, icecapPlat
}:

let

  dts = {
    virt = with dtb-helpers; decompile platUtils.virt.extra.dtb;
    rpi4 = with dtb-helpers; decompile "${raspios.latest.boot}/bcm2711-rpi-4-b.dtb";
  }.${icecapPlat};

  _source = makeOverridable' stdenv.mkDerivation {
    name = "sel4-kernel-source";
    src = seL4EcosystemRepos.seL4;
    nativeBuildInputs = [ python3 ];

    phases = [ "unpackPhase" "patchPhase" "installPhase" ];

    postPatch = ''
      # patchShebangs can't handle env -S
      rm configs/*_verified.cmake

      patchShebangs --build .

      cp ${dts} tools/dts/${{
        # The alignment of these names is a coincidence
        rpi4 = "rpi4";
        virt = "virt";
      }.${icecapPlat}}.dts
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
    include(${seL4EcosystemRepos.seL4}/configs/seL4Config.cmake)
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
makeOverridable' ({ source }: stdenvBoot.mkDerivation rec {
  name = "sel4";

  nativeBuildInputs = [
    cmake ninja rsync
    dtc libxml2
    python3Packages.sel4-deps
  ];

  phases = [
    "configurePhase" "buildPhase" "installPhase"
    # would fixupPhase be safe and beneficial?
  ];

  cmakeDir = linkFarm "x" [
    { name = "CMakeLists.txt";
      path = writeText "CMakeLists.txt" ''
        cmake_minimum_required(VERSION 3.13)
        project(seL4 ASM C)
        add_subdirectory(${source} kernel)
        add_subdirectory(${source}/libsel4 libsel4)
        install(TARGETS sel4 ARCHIVE DESTINATION lib)
      '';
    }
  ];

  # TODO
  cmakeBuildType = "Debug";

  cmakeFlags = [
    "-G" "Ninja"
    "-C" cacheScript
    # TODO
    "-DCROSS_COMPILER_PREFIX=${stdenvBoot.cc.targetPrefix}"
  ];

  buildPhase = ''
    ninja kernel.elf kernel/kernel.dtb sel4
  '';

  postInstall = ''
    install -D -t $out/boot kernel/kernel.elf kernel/kernel.dtb
    install -D -t $out/lib staging/lib/libsel4.a
    install -D -t $out/sel4-aux kernel/gen_headers/plat/machine/platform_gen.yaml

    mkdir -p $out/include

    includePrefixes="${lib.concatStringsSep " " [
      "libsel4" "${source}/libsel4"
    ]}"

    includeSuffixes="${lib.concatStringsSep " " [
      "include"
      "arch_include/arm"
      "sel4_arch_include/aarch64"
      "sel4_plat_include/${cmakeConfig.KernelPlatform.value}"
      "mode_include/64"
    ]}"

    for p in $includePrefixes; do
      for s in $includeSuffixes; do
        if [ -d $p/$s ]; then
          echo "installing headers from $p/$s"
          rsync -a $p/$s/ $out/include/
        fi
      done
    done

    rsync -a kernel/gen_config/ $out/include/ # is this necessary?
    rsync -a libsel4/gen_config/ $out/include/

    # HACK for access to generated source files during debugging
    mkdir -p $out/debug-aux/src
    cp -r kernel libsel4 $out/debug-aux/src

    # HACK export and propagate config in generic and CMake formats

    mkdir -p $out/sel4-config

    sed -n 's,^\([A-Za-z0-9][^:]*\):\([^=]*\)=\(.*\)$,\1:\2=\3,p' CMakeCache.txt \
      | grep -e '$.^' ${lib.concatMapStringsSep " " (prefix: "-e ^${prefix}") configPrefixes} \
      | sort \
      > $out/sel4-config/kernel.txt

    sed 's/^\([^:]*\):\([^=]*\)=\(.*\)$/set(\1 "\3" CACHE \2 "")/' $out/sel4-config/kernel.txt \
      > $out/sel4-config/kernel.cmake

    cat ${writeText "x" extraConfig} >> $out/sel4-config/kernel.cmake

    $AR r $out/lib/libsel4_autoconf.a
  '';

  passthru = {
    inherit dts source;
  };

}) {
  source = _source;
}
