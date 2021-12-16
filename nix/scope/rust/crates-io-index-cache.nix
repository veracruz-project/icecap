{ lib, runCommand, fetchgit
, globalCrates
}:

let
  git = fetchgit {
    url = "https://github.com/rust-lang/crates.io-index";
    rev = "63708ede2c67233eb146473cdcac9475f5e3d375";
    sha256 = "sha256-RDNvknWZcKgJvyp7zi4rvHWSBwM+Fbic+uI6zXOfz5A=";
    leaveDotGit = true;
    deepClone = false;
    postFetch = ''
      mv $out/.git tmp
      rm -r $out
      mv tmp $out
    '';
  };

  gitDep = patch:
    let
      dotGit = fetchgit {
        url = patch.src.hack.url;
        rev = patch.src.hack.rev;
        sha256 = patch.dotGitSha256;
        leaveDotGit = true;
        deepClone = false;
        postFetch = ''
          mv $out/.git tmp
          rm -r $out
          mv tmp $out
        '';
      };
    in ''
      d=$CARGO_HOME/git/db/${patch.cacheTag}
      ln -s ${dotGit} $d
      d=$CARGO_HOME/git/checkouts/${patch.cacheTag}/${builtins.substring 0 7 patch.src.hack.rev}
      mkdir -p $d
      ln -s ${patch.src}/* $d
      ln -s ${dotGit} $d/.git
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
