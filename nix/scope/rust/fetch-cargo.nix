{ lib, stdenv, runCommand, cacert, git, cargo }:

{ sha256, ... } @ args:

# TODO: normalize config.toml?

let

  fixed = stdenv.mkDerivation ({

    name = "vendor-fixed";

    # TODO
    # CARGO_HTTP_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    # TODO why need cacert in both?
    nativeBuildInputs = [ cacert git cargo ];
    buildInputs = [ cacert ];

    phases = [ "unpackPhase" "patchPhase" "installPhase" ];

    installPhase = ''
      runHook preInstall

      if [ ! -f Cargo.lock ]; then
          echo "ERROR: Cargo.lock does not exist"
          exit 1
      fi

      export CARGO_HOME=$(mktemp -d cargo-home.XXX)

      mkdir $out
      cargo vendor $out/vendor | sed s,$out,@self@, > $out/config.toml

      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = sha256;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
    preferLocalBuild = true;

  } // args);

in runCommand "vendor-config.toml" {
  passthru.directory = "${fixed}/vendor";
} ''
  substitute ${fixed}/config.toml $out --subst-var-by self ${fixed}
''
