{ lib, linux-ng, uboot-ng, makeOverridable' }:

rec {

  icecapSrc = rec {

    clean = cleanWithName null;

    cleanWithName = name: src: lib.cleanSourceWith {
      src = lib.cleanSource src;
      inherit name filter;
    };

    filter = name: type:
      let baseName = baseNameOf (toString name); in !(
        false
          # NOTE minimize this, just like .gitignore
          || baseName == "__pycache__" # for {c,d}dl.env
          || baseName == "target" # for src/rust (HACK)
      );

    absolute = absoluteWithName null;
    absoluteSplit = absoluteSplitWithName null;
    absoluteWithName = cleanWithName;
    absoluteSplitWithName = name: src: {
      store = absoluteWithName name src;
      env = toString src;
    };

    relative = relativeWithName null;
    relativeSplit = relativeSplitWithName null;
    relativeWithName = name: suffix: (relativeSplitWithName name suffix).store;
    relativeSplitWithName = name: suffix: absoluteSplitWithName name (relativeRaw suffix);
    relativeRaw = suffix: ../../src + "/${suffix}";

    splitTrivially = store: { inherit store; env = store; };
    extend = suffix: lib.mapAttrs (_: v: "${v}${suffix}");


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

  icecapExternalSrc = {

    seL4 = icecapSrc.repo {
      repo = "seL4";
      rev = "f547c10991aa88029f23da3b82c43f1dd908dd89";
    };

    capdl = icecapSrc.repo {
      repo = "capdl";
      rev = "ba7fbd6f661c8c70d6c7c11b943af41fe6072d6a";
    };

    # for elfloader and some python scripts
    seL4_tools = icecapSrc.repo {
      repo = "seL4_tools";
      rev = "81032a274e4bdf55aa1e065106f25e61e5758a1d";
    };

    linux.unified = linux-ng.doSource {
      version = "5.15.0";
      extraVersion = "-rc2";
      src = (icecapSrc.repo {
        repo = "linux";
        rev = "cfd8cbf6367b4c74c9544c4c41efb2c1681166d9"; # branch icecap
      }).store;
    };

    linux.rpi4 = linux-ng.doSource {
      version = "5.15.0";
      extraVersion = "-rc2";
      src = (icecapSrc.repo {
        repo = "linux";
        rev = "b532b351b477faeb9d2074ebd9247e8eaeb86a85"; # branch: icecap-rpi4
      }).store;
    };

    u-boot.host.unified = uboot-ng.doSource {
      version = "2019.07";
      src = (icecapSrc.repo {
        repo = "u-boot";
        rev = "64cc183d6b124f5804e7487ea457c99907a6cb7e"; # branch icecap-host
      }).store;
    };

    u-boot.firmware.rpi4 = with uboot-ng; doSource {
      version = "2019.07";
      src = (icecapSrc.repo {
        repo = "u-boot";
        rev = "6e73588b00397be29e2b91d279062e9372dc8092"; # branch icecap
      }).store;
    };

    crates.git =
      let
        mk = { repo, rev, cacheTag, dotGitSha256 }: rec {
          src = icecapSrc.repo {
            inherit repo rev;
          };
          inherit cacheTag dotGitSha256;
          dep = {
            git = src.hack.url;
            rev = src.hack.rev;
          };
        };
      in {
        dlmalloc = mk {
          repo = "rust-dlmalloc";
          rev = "f6759cfed44dc4135eaa43c8c26599357749af39"; # branch: icecap
          cacheTag = "rust-dlmalloc-e8402a3cfb2bf152";
          dotGitSha256 = "sha256-0K4E9XqmQV4J0UaHEarLf4pOHvOhg6vxTlZeleRTlBo=";
        };
        libc = mk {
          repo = "rust-libc";
          rev = "bcb2c71ab1377db89ca6bca3e234b8f9ea20c012"; # branch: icecap
          cacheTag = "rust-libc-TODO"; # TODO
          dotGitSha256 = "sha256-zUL33cMy9yWpdKvr9ss1R0KEAjhhiu7+B0q/OB6DcJA=";
        };
      };

  };
}
