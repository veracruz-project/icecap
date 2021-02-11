{ runCMake, stdenvBoot, repos
, muslc
, libsel4
}:

runCMake stdenvBoot rec {
  baseName = "sel4runtime";
  source = repos.clean.${baseName};

  propagatedBuildInputs = [
    muslc
    libsel4
  ];

  includeSuffixes = [
    "include"
    "include/mode/64"
    "include/arch/arm"
    "include/sel4_arch/aarch64"
  ];

  extraPostInstall = ''
    cp lib/* $out/lib
    cp lib/sel4_crt0.S.obj $out/lib/sel4_crt0.o
  '';

  configPrefixes = [
    "Sel4Runtime"
  ];

}
