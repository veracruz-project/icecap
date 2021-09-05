{ lib, linux-ng, uboot-ng }:

let
  clean = remote // {
    inherit (local)
      # seL4
      # capdl
      # seL4_tools
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

    seL4 = mk "seL4" {} "62f761d7e6304e8b18d926a050d81df512e6419e";
    capdl = mk "capdl" {} "dc37aaabf6486806e0e002cdff7ee05a1b23d5fc";

    # for elfloader
    seL4_tools = mk "minor-patches/seL4/seL4_tools" {} "80b6eb08966aa243373c26cb51fbb390aeb4ed8c";

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

in rec {
  inherit mkIceCapGitUrl mkIceCapKeepRef mkIceCapLocalPath mkIceCapSrc;
  inherit clean local remote;
  forceLocal = mkAttrs local;
  forceRemote = mkAttrs remote;

  icecapSrcRel = suffix: (icecapSrcRelSplit suffix).store;
  icecapSrcAbs = src: (icecapSrcAbsSplit src).store;
  icecapSrcRelRaw = suffix: ../../src + "/${suffix}";
  icecapSrcFilter = name: type: builtins.match ".*nix-shell\\.tmp.*" name == null; # TODO
  icecapSrcRelSplit = suffix: icecapSrcAbsSplit (icecapSrcRelRaw suffix);
  icecapSrcAbsSplit = src: {
    store = lib.cleanSourceWith {
      src = lib.cleanSource src;
      filter = icecapSrcFilter;
    };
    env = toString src;
  };

  mkTrivialSrc = store: { inherit store; env = store; };
  mkAbsSrc = path: { store = lib.cleanSource path; env = toString path; };

  linuxKernelUnifiedSource = with linux-ng; doSource {
    version = "5.6.0";
    extraVersion = "-rc2";
    src = (mkIceCapSrc {
      repo = "linux";
      rev = "a51b1b13cfa49ee6ff06a6807e9f68faf2de217f"; # branch icecap
    }).store;
  };

  uBootUnifiedSource = with uboot-ng; doSource {
    version = "2019.07";
    src = (mkIceCapSrc {
      repo = "u-boot";
      rev = "9626efe72a2200d3dc6852ce41e4c34f791833bf"; # branch icecap-host
    }).store;
  };

} // mkAttrs clean
