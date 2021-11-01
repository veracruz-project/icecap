{ lib, linkFarm, writeText, runCommand
, python3, python3Packages
, seL4EcosystemRepos
, kernel, libsel4
, libs, icecapSrc
}:

let

  py = runCommand "x.py" {
    nativeBuildInputs = [ python3 ];
  } ''
    install -D -t $out ${seL4EcosystemRepos.seL4_tools.extendInnerSuffix "cmake-tool/helpers"}/*.py ${kernel.patchedSource}/tools/hardware_gen.py
    patchShebangs --build $out
    cp -r ${kernel.patchedSource}/tools/hardware $out
  '';

  platformInfo = runCommand "platform_info.h" {
    nativeBuildInputs = [ python3 python3Packages.sel4-deps ];
  } ''
    ${py}/platform_sift.py --emit-c-syntax ${libsel4}/sel4-aux/platform_gen.yaml > $out
  '';

in
libs.mk {
  name = "capdl-loader-lib";
  root = icecapSrc.relativeSplit "c/boot/capdl-loader-core";
  propagatedBuildInputs = [
    libsel4
    libs.icecap-runtime-root
    libs.icecap-pure
    libs.icecap-utils
    libs.cpio
    libs.capdl-support-hack
  ];
  extra.CAPDL_LOADER_EXTERNAL_SOURCE = seL4EcosystemRepos.capdl.extendInnerSuffix "capdl-loader-app";
  extra.CAPDL_LOADER_PLATFORM_INFO_H = platformInfo;
  extra.CAPDL_LOADER_CONFIG_IN_H = writeText "config_in.h" ''
    #pragma once
    #define CONFIG_CAPDL_LOADER_MAX_OBJECTS 10000
  '';
}
