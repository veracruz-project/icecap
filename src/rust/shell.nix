let
  topLevel = import ../..;

  inherit (topLevel.pkgs) dev;
  inherit (topLevel.pkgs.none.icecap.configured) virt;
in

dev.mkShell {
  LIBCLANG_PATH = "${dev.lib.getLib dev.llvmPackages.libclang}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = [
    "-I${virt.libsel4}/include"
  ];

  LIBSEL4 = virt.libsel4;
  ICECAP_RUNTIME = virt.libs.icecap-runtime;

  nativeBuildInputs = with dev; [
    rustup
    git
    cacert
  ];
}
