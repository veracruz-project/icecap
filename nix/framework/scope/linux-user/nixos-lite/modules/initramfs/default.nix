{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.initramfs;

  allModules = cfg.includeModules ++ cfg.loadModules;

  mkExtraUtils = pkgs.callPackage ./mk-extra-utils.nix {};
  mkNixInitramfs = pkgs.callPackage ./mk-nix-initramfs.nix {};

  modulesClosure = pkgs.linuxHelpers.linux.mkModulesClosure {
    rootModules = allModules;
    kernel = modules;
    firmware = modules;
    allowMissing = true;
  };

  extraUtils = mkExtraUtils {
    inherit (cfg) extraUtilsCommands;
  };

  init = pkgs.writeTextFile {
    name = "init";
    executable = true;
    checkPhase = ''
      ${pkgs.buildPackages.busybox}/bin/ash -n $out
    '';
    text = ''
      #!${extraUtils}/bin/sh

      export LD_LIBRARY_PATH=${extraUtils}/lib
      export PATH=${extraUtils}/bin

      specialMount() {
        mkdir -m 0755 -p "$2"
        mount -n -t "$4" -o "$3" "$1" "$2"
      }
      specialMount proc /proc nosuid,noexec,nodev proc
      specialMount sysfs /sys nosuid,noexec,nodev sysfs
      specialMount devtmpfs /dev nosuid,strictatime,mode=755,size=5% devtmpfs
      specialMount devpts /dev/pts nosuid,noexec,mode=620,ptmxmode=0666 devpts 2>/dev/null || true # HACK not present in tiny realm kconfig

      console=${cfg.defaultConsole}
      for o in $(cat /proc/cmdline); do
        case $o in
          console=*)
            set -- $(IFS==; echo $o)
            params=$2
            set -- $(IFS=,; echo $params)
            console=$1
            ;;
        esac
      done

      interact() {
        setsid sh -c "ash -l </dev/$console >/dev/$console 2>/dev/$console"
      }

      fail() {
        echo "Failed. Starting interactive shell..." >/dev/$console
        interact
      }
      trap fail 0

      echo "=+= nixos lite =+="

      ${optionalString (cfg.modules != null) ''
        mkdir -p /lib
        echo ${extraUtils}/bin/modprobe > /proc/sys/kernel/modprobe
        ln -s ${modulesClosure}/lib/modules /lib/modules
        ln -s ${modulesClosure}/lib/firmware /lib/firmware
        for m in ${concatStringsSep " " cfg.loadModules}; do
          echo "loading module $m..."
          modprobe $m
        done
      ''}

      mkdir /run
      mkdir /tmp

      ${cfg.extraInitCommands}

      interact
    '';
  };

  profile = pkgs.writeText "profile" ''
    ${cfg.profile}
  '';

  initramfs =
    assert cfg.modules == null -> allModules == [];
    mkNixInitramfs {
      content = pkgs.runCommand "content" {
        nativeBuildInputs = [
          pkgs.buildPackages.nukeReferences
        ];
      } ''
        mkdir -p $out/etc
        ln -s ${init} $out/init
        ln -s ${profile} $out/etc/profile
        ${cfg.extraContentCommands}
      '';
    };

in {
  options = {

    initramfs.modules = mkOption {
      default = null;
      type = types.unspecified;
    };

    initramfs.includeModules = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    initramfs.loadModules = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    initramfs.extraUtilsCommands = mkOption {
      internal = true;
      default = "";
      type = types.lines;
      description = ''
        Shell commands to be executed in the builder of the
        extra-utils derivation.  This can be used to provide
        additional utilities in the initial ramdisk.
      '';
    };

    initramfs.profile = mkOption {
      default = "";
      type = types.lines;
    };

    initramfs.defaultConsole  = mkOption {
      default = "tty1";
      type = types.str;
    };

    initramfs.extraInitCommands = mkOption {
      default = "";
      type = types.lines;
      description = ''
        Shell commands to be executed in init
      '';
    };

    initramfs.extraContentCommands = mkOption {
      default = "";
      type = types.lines;
    };

  };

  config = {
    build = {
      inherit initramfs extraUtils;
    };
  };
}
