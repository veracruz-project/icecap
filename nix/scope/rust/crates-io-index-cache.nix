{ runCommand, fetchgit }:

let
  git = fetchgit {
    url = "https://github.com/rust-lang/crates.io-index";
    rev = "3d615886aab14af8bf5f88c3c4bb54aceae365e6";
    sha256 = "sha256-7jxvjDa2WyeR/y9xgNoiWQfqmcf7Gl446UbDjsYGq5M=";
    leaveDotGit = true;
    deepClone = false;
    postFetch = ''
      mv $out/.git tmp
      rm -r $out
      mv tmp $out
    '';
  };

in
  runCommand "cargo-home" {} ''
    export CARGO_HOME=$out
    d=$CARGO_HOME/registry/index/github.com-1ecc6299db9ec823 # TODO generate this hash using the cargo crates
    mkdir -p $d/.git
    ln -s ${git}/* $d/.git
    rm -r $d/.git/refs
    mkdir -p $d/.git/refs/remotes/origin
    echo ${git.rev} > $d/.git/refs/remotes/origin/HEAD
  ''
