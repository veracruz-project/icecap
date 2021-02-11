{ runCommand, fetchgit }:

let
  git = fetchgit {
    url = "https://github.com/rust-lang/crates.io-index";
    rev = "577cce4ea6ba2b824a31566d25d856718f0df0cb";
    sha256 = "sha256-FoOzQKIHfM1HzHBpPBNRowErD7f8z+kFa+kCwle57Ec=";
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
    echo ${git.rev} > $d/.git/refs/remotes/origin/master
  ''
