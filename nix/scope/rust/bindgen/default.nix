{ stdenv, fetchFromGitHub, writeShellScriptBin
, llvmPackages, clang
, fetchCargo, buildRustPackage
, rustfmt
, runtimeShell
, fetchCrates
}:

buildRustPackage rec {
  pname = "rust-bindgen";
  version = "0.53.0";
  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = pname;
    rev = "v${version}";
    sha256 = "0ncdk3fdxww0k1x0009gvizpcvnf4n3b7w9cvr4jixvv05jcbnm0";
  };

  cargoVendorConfig = fetchCrates "${src}/Cargo.lock";
  # cargoVendorConfig = fetchCargo {
  #   inherit src;
  #   sha256 = "0nb1wi31gdvalk6g645sya9bxlq3z8w1hwkxl6b5mxslk3605gba";
  # };

  LIBCLANG_PATH = "${libclang}/lib";
  libclang = llvmPackages.libclang.lib;
  inherit runtimeShell;

  buildInputs = [ libclang ];
  # propagatedNativeBuildInputs = [ clang ]; # to populate NIX_CXXSTDLIB_COMPILE

  doCheck = false;

  # checkInputs =
  #   let fakeRustup = writeShellScriptBin "rustup" ''
  #     shift
  #     shift
  #     exec "$@"
  #   '';
  # in [
  #   rustfmt
  #   fakeRustup
  #   clang.nativeDrv
  # ];

  # preCheck = ''
  #   patchShebangs ci
  # '';

  postInstall = ''
    mv $out/bin/{bindgen,.bindgen-wrapped};
    substituteAll ${./wrapper.sh} $out/bin/bindgen
    chmod +x $out/bin/bindgen
  '';

}
