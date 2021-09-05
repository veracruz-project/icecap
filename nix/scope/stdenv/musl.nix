{ stdenv }:

stdenv.mkDerivation rec {
  name = "musl";

  src = builtins.fetchGit {
    url = "https://github.com/sel4/musllibc";
    ref = "sel4";
    rev = "a0a3af0e3a54fb3985352b4a3160503ecc8c260c";
  };

  hardeningDisable = [ "all" ]; # TODO

  NIX_CFLAGS_COMPILE = [
    "-fdebug-prefix-map=.=${src}"
  ];

  dontDisableStatic = true;
  dontFixup = true;

  configureFlags = [
    "--enable-debug"
    "--enable-warnings"
    "--disable-shared"
    "--enable-static"
    "--disable-optimize"
  ];

  postConfigure = ''
    sed -i 's/^ARCH = \(.*\)/ARCH = \1_sel4/' config.mak
  '';

  makeFlags = [
    "-f" "Makefile.muslc"
  ];

  installTargets = [
    "install-headers"
  ];

  postInstall = ''
    mkdir -p $out/lib
    cp lib/libc.a lib/libm.a $out/lib
    ln -s $out/lib/libc.a $out/lib/libmuslc.a
    ln -s $out/lib/libc.a $out/lib/libg.a
  '';
}
