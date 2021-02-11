{ stdenvNonRoot, lib, fetchgit
, cmake, ninja, protobuf
, buildPackages
, patchSrc
, muslc
, libsel4runtime
}:

let

  env = buildPackages.python2.buildEnv.override {
    extraLibs = [
      buildPackages.python2Packages.protobuf
    ];
  };

  src = patchSrc {
    name = "nanopb-src";
    src = fetchgit {
      url = "https://github.com/nanopb/nanopb";
      rev = "847ac296b50936a8b13d1434080cef8edeba621c";
      sha256 = "0mx7cfjz794jv1f2rrfndalf0k11c5rgs668lbkcb514lw7d7mnf";
    };
    nativeBuildInputs = [ env ];
    postPatch = ''
      patchShebangs .
    '';
  };

in
stdenvNonRoot.mkDerivation {
  name = "nanopb";

  hardeningDisable = [ "all" ];

  inherit src;

  nativeBuildInputs = [
    cmake ninja protobuf
    env
  ];

  buildInputs = [
    muslc
    libsel4runtime
  ];

  NIX_CFLAGS_LINK = [
    "-lsel4runtime"
  ];

  cmakeBuildType = "Debug";

  dontFixup = true;

  passthru.cmake = ./nanopb.cmake;
}
