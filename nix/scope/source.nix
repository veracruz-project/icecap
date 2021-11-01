{ lib, linux-ng, uboot-ng, makeOverridable' }:

rec {

  icecapSrc = rec {

    clean = src: lib.cleanSourceWith {
      src = lib.cleanSource src;
      inherit filter;
    };

    filter = name: type:
      let baseName = baseNameOf (toString name); in !(
        false
          # NOTE minimize this, just like .gitignore
          || baseName == "__pycache__" # for {c,d}dl.env
      );

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

      { repo, ref ? null, rev, submodules ? false, local ? false, localGit ? false, innerSuffix ? "", outerSuffix ? "" } @ args:

        let
          url = if localGit then localPathOf repo else gitUrlOf repo;
          ref_ = if ref != null then ref else keepRefOf rev;

          remoteBase = builtins.fetchGit {
            inherit url rev submodules;
            ref = ref_;
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

          # HACK
          hack = {
            inherit url rev;
            ref = ref_;
            rawRef = "icecap/keep/${builtins.substring 0 32 rev}";
          };
        }
    ));

  };

  seL4EcosystemRepos = {

    seL4 = icecapSrc.repo {
      repo = "seL4";
      rev = "f547c10991aa88029f23da3b82c43f1dd908dd89";
    };

    capdl = icecapSrc.repo {
      repo = "capdl";
      rev = "e8501a4cd61ee9b4e2b0e51668c739d3720840cf";
    };

    # for elfloader and some python scripts
    seL4_tools = icecapSrc.repo {
      repo = "seL4_tools";
      rev = "dce0461e3092fe2bbcd38261e34a8ed8f8bdf580";
    };

  };

  linuxKernelUnifiedSource = with linux-ng; doSource {
    version = "5.15.0";
    extraVersion = "-rc2";
    src = (icecapSrc.repo {
      repo = "linux";
      rev = "1cb24ed03f2480f0f490cf84b81d83eebd9097c4"; # branch icecap
    }).store;
  };

  linuxKernelRpi4Source = with linux-ng; doSource {
    version = "5.15.0";
    extraVersion = "-rc2";
    src = (icecapSrc.repo {
      repo = "linux";
      rev = "901292d22770fb16638d1f4ef8d5efff27a2db01"; # branch: icecap-rpi4
    }).store;
  };

  uBootUnifiedSource = with uboot-ng; doSource {
    version = "2019.07";
    src = (icecapSrc.repo {
      repo = "u-boot";
      rev = "ad3de5e2cffe741371b50b2f58c82eba0b8edb96"; # branch icecap-host
    }).store;
  };

}
