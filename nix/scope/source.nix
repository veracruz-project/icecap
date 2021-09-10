{ lib, linux-ng, uboot-ng, makeOverridable' }:

rec {

  icecapSrc = rec {

    filter = name: type: true; # TODO
    clean = src: lib.cleanSourceWith {
      src = lib.cleanSource src;
      inherit filter;
    };

    absolute = clean;
    absoluteSplit = src: {
      store = absolute src;
      env = toString src;
    };

    relative = suffix: (relativeSplit suffix).store;
    relativeSplit = suffix: absoluteSplit (relativeRaw suffix);
    relativeRaw = suffix: ../../src + "/${suffix}";

    splitTrivially = store: { inherit store; env = store; };


    gitUrlOf = repo: "https://gitlab.com/arm-research/security/icecap/${repo}";
    keepRefOf = rev: "refs/tags/icecap/keep/${builtins.substring 0 32 rev}";

    localPathOf = repo: ../../../local + "/${repo}";

    localPathWithBranchOf = repo: branch:
      let
        withoutBranch = ../../../local + "/${repo}";
        withBranch = withoutBranch + "+${branch}";
      in if builtins.pathExists withBranch then withBranch else withoutBranch;


    repo = lib.fix (self: makeOverridable' (

      { repo, ref ? null, rev, submodules ? false, local ? false, innerSuffix ? "", outerSuffix ? "" } @ args:

        let

          remoteBase = builtins.fetchGit {
            inherit rev submodules;
            url = gitUrlOf repo;
            ref = if ref != null then ref else keepRefOf rev;
          };

          remoteIntermediate = "${remoteBase}/${innerSuffix}";
          localIntermediate = toString (clean (localPathOf repo + "/${innerSuffix}"));
          envIntermediate = "${toString (localPathOf repo)}/${innerSuffix}";

        in rec {

          store = (if local then localIntermediate else remoteIntermediate) + outerSuffix;
          env = (if local then envIntermediate else remoteIntermediate) + outerSuffix;

          # hack or great idea?
          outPath = store;

          # convenient overrides
          extendInnerSuffix = suffix: (self args).override' (attrs: { innerSuffix = (attrs.innerSuffix or "") + suffix; });
          extendOuterSuffix = suffix: (self args).override' (attrs: { outerSuffix = (attrs.outerSuffix or "") + suffix; });
          forceLocal = (self args).override' { local = true; };
          forceRemote = (self args).override' { local = false; };
        }
    ));

  };

  seL4EcosystemRepos = {

    seL4 = icecapSrc.repo {
      repo = "seL4";
      rev = "64b3280545ac01e843d88bb351753b550819bc2a";
      # local = true;
    };

    capdl = icecapSrc.repo {
      repo = "capdl";
      rev = "dc37aaabf6486806e0e002cdff7ee05a1b23d5fc";
      # local = true;
    };

    # for elfloader and some python scripts
    seL4_tools = icecapSrc.repo {
      repo = "minor-patches/seL4/seL4_tools";
      rev = "80b6eb08966aa243373c26cb51fbb390aeb4ed8c";
      # local = true;
    };

  };

  linuxKernelUnifiedSource = with linux-ng; doSource {
    version = "5.6.0";
    extraVersion = "-rc2";
    src = (icecapSrc.repo {
      repo = "linux";
      rev = "ded4f69aca0b557c6ead0a21b62e01e19bd2aceb"; # branch icecap
    }).store;
  };

  linuxKernelRpi4Source = with linux-ng; doSource {
    version = "5.4.47";
    src = (icecapSrc.repo {
      repo = "linux";
      rev = "d06f317d7cf08f0d81febde505925893335ecc7f"; # branch: icecap-rpi4
    }).store;
  };

  uBootUnifiedSource = with uboot-ng; doSource {
    version = "2019.07";
    src = (icecapSrc.repo {
      repo = "u-boot";
      rev = "9626efe72a2200d3dc6852ce41e4c34f791833bf"; # branch icecap-host
    }).store;
  };

}
