{ runCommand
, python3, python3Packages
, icecapExternalSrc
, libsel4
}:

runCommand "platform_info.h" {
  nativeBuildInputs = [ python3 python3Packages.sel4-deps ];
} ''
  python3 ${icecapExternalSrc.seL4_tools.extendInnerSuffix "cmake-tool/helpers"}/platform_sift.py \
      --emit-c-syntax ${libsel4}/sel4-aux/platform_gen.yaml > $out
''
