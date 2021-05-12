{ runCommandNoCC, python3Packages }:

{ name, version, url, rev, param } @ args:

let
  src = builtins.fetchGit {
    inherit url rev;
    allRefs = true; # HACK
    submodules = true;
  };

in runCommandNoCC "${name}-${version}" {
  nativeBuildInputs = [ python3Packages.toml ];
  passthru.crateMeta = args // {
    source = "git";
  };
} ''
  set -o pipefail

  manifest=$(find ${src} -type f -name Cargo.toml | python3 ${./find-crate.py} ${name})
  d=$(dirname $manifest)
  cp -pr --no-preserve=owner,mode $d $out

  rm -rf $out/fuzz $out/.gitignore # HACK?
  pushd $out
    find . -type f -exec sha256sum {} \; | python3 ${./unpack-helper.py}
  popd
''
