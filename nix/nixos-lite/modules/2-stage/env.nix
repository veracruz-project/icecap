{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.env;

in {
  options = {

    env.extraPackages = mkOption {
      default = [];
      type = types.unspecified;
    };

  };

  config = {

    build.env = with pkgs; buildEnv {
      name = "env";
      ignoreCollisions = true;
      paths = map (setPrio 8) [
        acl
        attr
        # bashInteractive # bash with ncurses support
        coreutils-full
        curl
        diffutils
        findutils
        gawk
        stdenv.cc.libc
        gnugrep
        gnupatch
        gnused
        less
        ncurses
        netcat
        procps
        strace
        su
        time
        utillinux
        which # 88K size
      ] ++ cfg.extraPackages ++ [
        (setPrio 9 busybox)
      ];
      postBuild = ''
        # Remove wrapped binaries, they shouldn't be accessible via PATH.
        find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete
      '';
    };
  };
}
