{ lib, runCommand, fetchgit
, globalCrates
}:

let
  git = fetchgit {
    url = "https://github.com/rust-lang/crates.io-index";
    rev = "4a1533efb084a8f67ca803e41b8592f4471c4827";
    sha256 = "sha256-w60yg4iKlROHDOf9LeS+rK6HPYY67OUTiApGVuAJwJc=";
    leaveDotGit = true;
    deepClone = false;
    postFetch = ''
      mv $out/.git tmp
      rm -r $out
      mv tmp $out
    '';
  };

  gitDep = { srcWithDotGit, rev, cacheTag, ... }: ''
    d=$CARGO_HOME/git/db/${cacheTag}
    ln -s ${srcWithDotGit}/.git $d
    d=$CARGO_HOME/git/checkouts/${cacheTag}/${builtins.substring 0 7 rev}
    mkdir -p $d
    ln -s ${srcWithDotGit}/* $d
    ln -s ${srcWithDotGit}/.git $d
    touch $d/.cargo-ok
  '';

  patches = globalCrates._patches;

in
  runCommand "cargo-home" {} ''
    export CARGO_HOME=$out
    d=$CARGO_HOME/registry/index/github.com-1ecc6299db9ec823 # TODO generate this hash using the cargo crates
    mkdir -p $d/.git
    ln -s ${git}/* $d/.git
    rm -r $d/.git/refs
    mkdir -p $d/.git/refs/remotes/origin
    echo ${git.rev} > $d/.git/refs/remotes/origin/HEAD

    mkdir -p $CARGO_HOME/git/db $CARGO_HOME/git/checkouts

    ${lib.concatMapStrings gitDep (lib.attrValues patches)}
  ''
