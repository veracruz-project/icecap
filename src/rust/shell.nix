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

  nativeBuildInputs = with dev; [
    rustup
    git
    cacert
  ];
}
