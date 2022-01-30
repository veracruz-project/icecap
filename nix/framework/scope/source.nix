{ lib, fetchgit, linuxHelpers, makeOverridable', icecapFrameworkConfig }:

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
    relativeRaw = suffix: ../../../src + "/${suffix}";

    splitTrivially = store: { inherit store; env = store; };
    extend = suffix: lib.mapAttrs (_: v: "${v}${suffix}");

    inherit (icecapFrameworkConfig.source) gitUrlOf keepRefOf localPathOf;

    localPathWithBranchOf = repo: branch:
      let
        withoutBranch = localPathOf repo;
        withBranch = withoutBranch + "+${branch}";
      in if builtins.pathExists withBranch then withBranch else withoutBranch;


    repo = lib.fix (self: makeOverridable' (

      { repo, ref ? null, rev, submodules ? false
      , sha256 ? null
      , local ? false, localGit ? false
      , innerSuffix ? "", outerSuffix ? ""
      } @ args:

        let
          url = if localGit then localPathOf repo else gitUrlOf repo;
          ref_ = if ref != null then ref else keepRefOf rev;

          remoteBase = if localGit != false || sha256 == null then builtins.fetchGit {
            inherit url rev submodules;
            ref = ref_;
          } else fetchgit {
            inherit url;
            rev = assert ref == null; ref_; # use keep ref to enforce its existence
            fetchSubmodules = submodules;
            inherit sha256;
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
          };
        }
    ));

    fetchGitWrapper = { url, ref ? null, rev, submodules ? false , sha256 ? null }:
      assert ref == null -> sha256 != null;
      if sha256 == null then builtins.fetchGit {
        inherit url ref rev submodules;
      } else fetchgit {
        inherit url rev sha256;
        fetchSubmodules = submodules;
      };

  };

  icecapExternalSrc = {

    seL4 = icecapSrc.repo {
      repo = "seL4";
      rev = "f547c10991aa88029f23da3b82c43f1dd908dd89";
    };

    capdl = icecapSrc.repo {
      repo = "capdl";
      rev = "2f78d999185e71d50cac9cb7033b738bb2510f47";
    };

    # for elfloader and some python scripts
    seL4_tools = icecapSrc.repo {
      repo = "seL4_tools";
      rev = "81032a274e4bdf55aa1e065106f25e61e5758a1d";
    };

    linux.unified = linuxHelpers.linux.prepareSource {
      version = "5.15.0";
      extraVersion = "-rc2";
      src = (icecapSrc.repo {
        repo = "linux";
        rev = "e07825c12c90781c79a5f1a71235df5cc7a46b8d"; # branch icecap
        sha256 = "sha256-brkU3EZUsJqKKrMVUXfFL9qrwCceX5V+03JPlpAbI30=";
      }).store;
    };

    linux.rpi4 = linuxHelpers.linux.prepareSource {
      version = "5.15.0";
      extraVersion = "-rc2";
      src = (icecapSrc.repo {
        repo = "linux";
        rev = "ca056d991d96846967fb76e93fc020e41b9cea42"; # branch: icecap-rpi4
        sha256 = "sha256-MH18Hi8a5ntnCaIiDX5X29buxUlJv0P4c8qbfkoTapY=";
      }).store;
    };

    u-boot.host.unified = linuxHelpers.uBoot.prepareSource {
      version = "2019.07";
      src = (icecapSrc.repo {
        repo = "u-boot";
        rev = "64cc183d6b124f5804e7487ea457c99907a6cb7e"; # branch icecap-host
      }).store;
    };

    u-boot.firmware.rpi4 = linuxHelpers.uBoot.prepareSource {
      version = "2019.07";
      src = (icecapSrc.repo {
        repo = "u-boot";
        rev = "6e73588b00397be29e2b91d279062e9372dc8092"; # branch icecap
      }).store;
    };

    crates.git =
      let
        mk = { repo, rev, sha256 ? null, sha256WithDotGit, cacheTag }:
          let
            url = icecapSrc.gitUrlOf repo;
          in {
            srcWithDotGit = fetchgit {
              inherit url;
              rev = icecapSrc.keepRefOf rev;
              sha256 = sha256WithDotGit;
              leaveDotGit = true;
              deepClone = false;
            };
            srcSplit = icecapSrc.repo {
              inherit repo rev sha256;
            };
            inherit rev cacheTag;
            dep = {
              git = url;
              inherit rev;
            };
        };
      in {
        dlmalloc = mk {
          repo = "rust-dlmalloc";
          rev = "f6759cfed44dc4135eaa43c8c26599357749af39"; # branch: icecap
          cacheTag = "rust-dlmalloc-e8402a3cfb2bf152";
          sha256WithDotGit = "sha256-gcpNxRBHHv9m0RZbIWGXO+PqCUJa2y3Xlk73KjXt3OI=";
        };
        libc = mk {
          repo = "rust-libc";
          rev = "bcb2c71ab1377db89ca6bca3e234b8f9ea20c012"; # branch: icecap
          cacheTag = "rust-libc-TODO"; # TODO
          sha256WithDotGit = "sha256-mQNTbPO1BKQLfdeX1MoTuBSIzDT0TQl9kxw1xWdeXIU=";
        };
      };

  };
}
