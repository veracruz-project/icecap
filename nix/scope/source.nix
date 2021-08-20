{ lib }:

let
  clean = remote // {
    inherit (local)
      # capdl
      # seL4
    ;
  };

  local = repos mkLocal;
  remote = repos mkRemote;

  mkBase = path: {}: rev: mkIceCapSrc {
    repo = path;
    inherit rev;
  };

  mkRemote = path: args: rev: (mkBase path args rev).store;
  mkLocal = path: args: rev: (mkBase path args rev).forceLocal.store;

  repos = mk: {

    seL4 = mk "seL4" {} "e28f2cda60127eee9d2a35f32ac46d86742a839a";
    capdl = mk "capdl" {} "433a8fd698e6f39f13acc9849ce714ecd2fd8f86";

    # for elfloader
    seL4_tools = mk "minor-patches/seL4/seL4_tools" {} "e211b270066fd5841d4ea994df077583a9d99126";

    # for use with MirageOS
    musllibc = fetchSeL4 {
      repo = "musllibc";
      ref = "sel4";
      rev = "a0a3af0e3a54fb3985352b4a3160503ecc8c260c";
    };
  };

  mkAttrs = repos: {
    rel = lib.mapAttrs (k: v: relOf v) repos;
    relLib = lib.mapAttrs (k: v: suffix: relOf v "lib${suffix}") repos;
  };

  relOf = path: suffix: path + "/${suffix}";

  fetchSeL4 = { repo, ref ? "master", rev }: builtins.fetchGit {
    url = "https://github.com/sel4/${repo}";
    inherit ref rev;
  };

  mkIceCapGitUrl = repo: "https://gitlab.com/arm-research/security/icecap/${repo}";
  mkIceCapKeepRef = rev: "refs/tags/icecap/keep/${builtins.substring 0 32 rev}";

  mkIceCapLocalPath = repo: ref:
    let
      base = ../../../local + "/${repo}";
      withBranch = base + "+${ref}";
    in if builtins.pathExists withBranch then withBranch else base;

  mkIceCapSrc = { repo, rev ? null, submodules ? false, local ? false, suffix ? "", postfix ? "" } @ args:
    let
      ref = mkIceCapKeepRef rev;
      local_ = local;
    in rec {
      remoteTop = builtins.fetchGit {
        url = mkIceCapGitUrl repo;
        inherit ref rev submodules;
      };
      remote = "${remoteTop}${suffix}";
      local = lib.cleanSourceWith {
        # TODO generalize
        filter = name: type: builtins.match ".*nix-shell\\.tmp.*" name == null && builtins.match ".*dist-newstyle.*" name == null;
        src = lib.cleanSource (mkIceCapLocalPath repo ref + "/${suffix}");
      };
      store = (if local_ then local else remote) + postfix;
      envRaw = "${toString (mkIceCapLocalPath repo ref)}/${suffix}${postfix}";
      env = if local_ then envRaw else remote;
      override = newArgs: mkIceCapSrc (args // newArgs);
      withSuffix = suffix_: override { suffix = suffix + suffix_; };
      withPostfix = postfix_: override { postfix = postfix + postfix_; };
      forceLocal = override { local = true; };
    };

in {
  inherit mkIceCapGitUrl mkIceCapKeepRef mkIceCapLocalPath mkIceCapSrc;
  inherit clean local remote;
  forceLocal = mkAttrs local;
  forceRemote = mkAttrs remote;
} // mkAttrs clean
