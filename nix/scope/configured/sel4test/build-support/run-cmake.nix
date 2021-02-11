# HACK

{ lib, runCommand, writeText
, cmake, ninja, rsync

, mkCMakeTop
, repos

, libsel4, libsel4runtime, muslc

, cmakeConfig
}:

let
  # TODO graph traversal to minimize repetition
  allLibs = x:
    let
      f = { requiresLibs ? [], propagatedBuildInputs ? [], ... }:
        requiresLibs ++ lib.concatMap f propagatedBuildInputs;
      raw = map (x: "-l${x}") (lib.unique (f x));
    in
      [ "-Wl,--start-group" ] ++ raw ++ [ "-Wl,--end-group" ];

  allProp = x:
    let
      g = lib.concatMap f;
      f = { outPath, propagatedBuildInputs ? [], ... }:
        [ outPath ] ++ g propagatedBuildInputs;
    in lib.unique (g x);

  allConfig = x:
    let
      g = lib.concatMap f;
      f = { outPath, propagatedBuildInputs ? [], ... }:
        [ outPath ] ++ g propagatedBuildInputs;
      raw = lib.unique (g x);
    in
      lib.concatMapStrings (path: ''
        file(GLOB scripts ${path}/sel4-config/*.cmake)
        foreach(script ''${scripts})
          include(''${script})
        endforeach()
      '') raw;

  autoconf = inputs: selfGen: runCommand "autoconf" {} ''
    h=$out/include/autoconf.h
    mkdir -p $(dirname $h)

    cat << EOF >> $h
    #pragma once
    EOF

    for dep in ${lib.concatStringsSep " " inputs}; do
      headers="$(find $dep -path "*/include/*/gen_config.h" | sed -r 's,^.*/include/(.*)$,\1,')"
      for header in $headers; do
        echo "#include <$header>" >> $h
      done
    done

    cat << EOF >> $h
    ${lib.concatMapStrings (x: ''
      #include <${x}/gen_config.h>
    '') selfGen}
    EOF
  '';

  filterInitConfig = with lib;
    all: prefixes: filterAttrs (k: v: any (prefix: hasPrefix prefix k) prefixes) all;

in

stdenv:

{ baseName ? null
, name ? "lib${baseName}"
, source ? null
, targets ? [ baseName ]
, phases ? [ "configurePhase" "buildPhase" "installPhase" "fixupPhase" /* TODO make sure fixupPhase is safe */ ]
, hardeningDisable ? [ "all" ]

, buildPhase ? ''
    ninja ${lib.concatStringsSep " " targets}
  ''

, extraBuildInputs ? []
, buildInputs ? [
    (autoconf (extraBuildInputs ++ allProp propagatedBuildInputs) selfGen)
  ] ++ extraBuildInputs

, extraNativeBuildInputs ? []
, nativeBuildInputs ? [
    cmake ninja rsync
  ] ++ extraNativeBuildInputs

, extraPropagatedBuildInputs ? []
, propagatedBuildInputs ? [
    libsel4
  ] ++ extraPropagatedBuildInputs

, cmakeBuildType ? "Debug"

, cmakeDir ? mkCMakeTop ''
    project(${name} ASM C)

    include(${repos.rel.seL4 "tools/helpers.cmake"})
    include(${repos.rel.seL4 "tools/internal.cmake"})

    ${cmakeBody}

    install(TARGETS ${lib.concatStringsSep " " targets}
      ARCHIVE DESTINATION lib
      RUNTIME DESTINATION bin
    )
  ''

, cmakeBody ? ''
    if(DEFINED ENV{NIX_SHELL_SRC})
      set(source $ENV{NIX_SHELL_SRC})
    else()
      set(source ${source})
    endif()

    ${extraCMakeBody}

    add_subdirectory(''${source} x)
  ''

, extraCMakeBody ? ""

, extraCMakeFlags ? []
, cmakeFlags ? [
    "-G" "Ninja"
    "-C" cacheScript
    # TODO
    "-DCROSS_COMPILER_PREFIX=${stdenv.cc.targetPrefix}"
  ] ++ extraCMakeFlags

, extraIncludePrefixes ? []
, includePrefixes ? [
    "x"
    source
  ] ++ extraIncludePrefixes

, extraIncludeSuffixes ? []
, includeSuffixes ? [
    "include"
    "arch_include/arm"
    "sel4_arch_include/aarch64"
    "plat_include/${cmakeConfig.KernelPlatform.value}"
  ] ++ extraIncludeSuffixes

, extraPostInstall ? ""
, postInstall ? ''
    # TODO
    for d in $(ls staging); do
      install -D -t $out/$d staging/$d/*
    done

    mkdir -p $out/include

    for p in $includePrefixes; do
      for s in $includeSuffixes; do
        if [ -d $p/$s ]; then
          echo "installing headers from $p/$s"
          rsync -a $p/$s/ $out/include/
        fi
      done
    done

    find . -type d \( -name gen_config -o -name gen_headers \) -exec rsync -a {}/ $out/include/ \;

    mkdir -p $out/sel4-config
    sed -n '/^\([A-Za-z0-9][^:]*\):\([^=]*\)=\(.*\)$/p' CMakeCache.txt \
      | (grep -e '$.^' ${lib.concatMapStringsSep " " (prefix: "-e ^${prefix}") configPrefixes} || true) \
      | sort \
      | tee $out/sel4-config/${configName}.txt \
      | sed 's/^\([^:]*\):\([^=]*\)=\(.*\)$/set(\1 "\3" CACHE \2 "")/' \
      > $out/sel4-config/${configName}.cmake

    cat ${writeText "x" extraConfig} >> $out/sel4-config/${configName}.cmake

    ${extraPostInstall}
  ''
    # ${lib.concatMapStrings (x: ''
    #   $AR r $out/lib/${x}_Config.a
    # '') selfGen}

, providesLibs ? targets
, requiresLibs ? (lib.concatMap (dep: dep.providesLibs or []) propagatedBuildInputs)

, extraCFlagsLink ? []
, NIX_CFLAGS_LINK ? [
    "-static "
    # "-z" "max-page-size=0x1000"
  ] ++ lib.optionals (stdenv.isRoot or false) [
    "-T" ./tls-rootserver.lds
  ] ++ allLibs {
    inherit requiresLibs propagatedBuildInputs;
  } ++ extraCFlagsLink

, extraCFlagsCompile ? []
, NIX_CFLAGS_COMPILE ? [
    "-funwind-tables"
    "-D__KERNEL_64__"
    "-gdwarf-5"
    # "-Wall" # TODO
    # "-Werror" # TODO
    "-Ix/gen_config"
    "-Ixx/gen_config"
  ] ++ extraCFlagsCompile

, extraPassthru ? {}
, passthru ? extraPassthru // {
    inherit
      providesLibs
      requiresLibs
      ;
  }

, dontStrip ? true
, dontPatchELF ? true

, configPrefixes ? []
, configName ? baseName
, extraInitConfig ? ""
, extraConfig ? ""
, cacheScript ? writeText "config.cmake" ''
    ${allConfig propagatedBuildInputs}

    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      set(${k} ${v.value} CACHE ${v.type} "")
    '') (filterInitConfig cmakeConfig configPrefixes))}

    ${extraInitConfig}
  ''
, selfGen ? (if lib.length configPrefixes == 0 then [] else targets)

, ... } @ args:

stdenv.mkDerivation (lib.flip removeAttrs [
  "providesLibs"
  "requiresLibs"
  "extraPassthru"
  "configPrefixes"
  "configName"
  "initConfig"
  "extraInitConfig"
  "cacheScript"
  "selfGen"
  "extraCFlagsCompile"
  "extraCFlagsLink"
  "extraBuildInputs"
  "extraNativeBuildInputs"
] args // {
  inherit
    name
    phases
    buildPhase
    buildInputs
    nativeBuildInputs
    propagatedBuildInputs
    hardeningDisable
    cmakeBuildType
    cmakeDir
    cmakeFlags
    includePrefixes
    includeSuffixes
    postInstall
    NIX_CFLAGS_LINK
    NIX_CFLAGS_COMPILE
    passthru
    dontStrip
    dontPatchELF
    ;
})
