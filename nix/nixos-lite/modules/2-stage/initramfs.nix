{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.initramfs;

  env = config.build.env;

  allModules = cfg.includeModules ++ cfg.loadModules;

  modulesClosure = pkgs.nixosLite.mkModulesClosure {
    rootModules = allModules;
    kernel = modules;
    firmware = modules;
    allowMissing = true;
  };

  extraUtils = pkgs.nixosLite.mkExtraUtils {
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
      specialMount devpts /dev/pts nosuid,noexec,mode=620,ptmxmode=0666 devpts

      console=${cfg.defaultConsole}
      for o in $(cat /proc/cmdline); do
        case $o in
          console=*)
            set -- $(IFS==; echo $o)
            params=$2
            set -- $(IFS=,; echo $params)
            console=$1
            ;;
          init=*)
            set -- $(IFS==; echo $o)
            next_init=$2
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

      mkdir -p /lib
      echo ${extraUtils}/bin/modprobe > /proc/sys/kernel/modprobe
      ${optionalString (cfg.modules != null) ''
        ln -s ${modulesClosure}/lib/modules /lib/modules
        ln -s ${modulesClosure}/lib/firmware /lib/firmware
        for m in ${concatStringsSep " " cfg.loadModules}; do
          echo "loading module $m..."
          modprobe $m
        done
      ''}

      mkdir /run
      mkdir /tmp

      target_root=/mnt-root
      mkdir -p $target_root
      mount -n -t tmpfs -o nosuid,nodev,strictatime tmpfs $target_root

      nix_store_mnt=$target_root/nix/store
      mkdir -p $nix_store_mnt

      ${cfg.mntCommands}

      if [ ! -e "$target_root/$next_init" ] && [ ! -L "$target_root/$next_init" ] ; then
          echo "next init script ($target_root/$next_init) not found"
          fail
      fi

      moveMount() {
        mkdir -m 0755 -p "$target_root/$1"
        mount --move "$1" "$target_root/$1"
      }
      moveMount /proc
      moveMount /sys
      moveMount /dev

      exec env -i console=$console $(type -P switch_root) "$target_root" "$next_init"
      fail
    '';
  };

  nextInit = pkgs.writeTextFile {
    name = "init";
    executable = true;
    checkPhase = ''
      ${pkgs.buildPackages.busybox}/bin/ash -n $out
    '';
    text = ''
      #!${pkgs.runtimeShell}
      export PATH=${env}/bin
      export LS_COLORS=

      mkdir -p /etc /bin /run /tmp
      ln -s ${pkgs.busybox}/bin/sh /bin/sh
      ln -s ${profile} /etc/profile

      ${cfg.extraNextInit}

      setsid sh -c "ash -l </dev/$console >/dev/$console 2>/dev/$console"
    '';
  };

  profile = pkgs.writeText "profile" ''
    ${cfg.profile}
  '';

  initramfs =
    assert cfg.modules == null -> allModules == [];
    pkgs.nixosLite.mkNixInitramfs {
      content = pkgs.runCommand "content" {} ''
        mkdir -p $out/etc
        ln -s ${init} $out/init
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

    initramfs.mntCommands = mkOption {
      default = "";
      type = types.lines;
    };

    initramfs.extraNextInit = mkOption {
      default = "";
      type = types.lines;
    };

  };

  config = {
    build = {
      inherit initramfs nextInit extraUtils;
    };
  };
}
