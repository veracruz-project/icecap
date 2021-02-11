{ lib, buildPackages, runCommand, writeText, writeTextFile
, busybox, kmod
, mkModulesClosure
, mkExtraUtils
, mkNixInitramfs
}:

{ compress ? "gzip -9n"
, defaultConsole ? "tty1"

, modules ? null
, includeModules ? []
, loadModules ? []

, extraUtilsCommands ? ""
, extraInitCommands ? ""
, extraProfileCommands ? ""

, passthru ? {}
}:

let
  allModules = includeModules ++ loadModules;
in

assert modules == null -> allModules == [];

with lib;

let

  modulesClosure = mkModulesClosure {
    rootModules = allModules;
    kernel = modules;
    firmware = modules;
    allowMissing = true;
  };

  extraUtils = mkExtraUtils {
    inherit extraUtilsCommands;
  };

  init = writeTextFile {
    name = "init";
    executable = true;
    checkPhase = ''
      ${buildPackages.busybox}/bin/ash -n $out
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
      specialMount tmpfs /run nosuid,nodev,strictatime,mode=755,size=25% tmpfs

      console=${defaultConsole}
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
      ${optionalString (modules != null) ''
        ln -s ${modulesClosure}/lib/modules /lib/modules
        ln -s ${modulesClosure}/lib/firmware /lib/firmware
        for m in ${concatStringsSep " " loadModules}; do
          echo "loading module $m..."
          modprobe $m
        done
      ''}

      ${extraInitCommands}

      interact
    '';
  };

  profile = writeText "profile" ''
    ${extraProfileCommands}
  '';

in mkNixInitramfs {
  content = runCommand "content" {} ''
    mkdir -p $out/etc
    ln -s ${init} $out/init
    ln -s ${profile} $out/etc/profile
  '';
  inherit compress;
  passthru = passthru // {
    inherit extraUtils;
  };
}
