let
  topLevel = import ../..;
  framework = topLevel.framework;

  inherit (framework.pkgs) dev;

  plat = "virt";

  configured = framework.pkgs.none.icecap.configured.${plat};
in

dev.mkShell {

  ICECAP_PLAT = plat;

  LIBSEL4 = configured.libsel4;
  ICECAP_RUNTIME = configured.userC.nonRootLibs.icecap-runtime;

  LIBCLANG_PATH = "${dev.lib.getLib dev.llvmPackages.libclang}/lib";

  nativeBuildInputs = with dev; [
    rustup
    git
    cacert
  ];
}
