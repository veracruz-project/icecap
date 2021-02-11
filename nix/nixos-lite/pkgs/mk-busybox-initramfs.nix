{ stdenv, lib, writeScript, writeText
, rsync, gzip, cpio
, squashfsTools
, busybox-static
}:

{ compress ? "gzip -9n"
, defaultConsole ? "tty1"
, extraInit ? ""
, extraProfile ? ""
, extraBuild ? ""
}:

let
  init = writeScript "init" ''
    #!/bin/sh

    specialMount() {
      mkdir -m 0755 -p "$2"
      mount -n -t "$4" -o "$3" "$1" "$2"
    }
    specialMount proc /proc nosuid,noexec,nodev proc
    specialMount sysfs /sys nosuid,noexec,nodev sysfs
    specialMount devtmpfs /dev nosuid,strictatime,mode=755,size=5% devtmpfs
    specialMount devpts /dev/pts nosuid,noexec,mode=620,ptmxmode=0666 devpts

    console=${defaultConsole}
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
      setsid sh -c "sh </dev/$console >/dev/$console 2>/dev/$console"
    }

    fail() {
      echo "Failed. Starting interactive shell..." >/dev/$console
      interact
    }
    trap fail 0

    ${extraInit}

    interact
  '';

  profile = writeText "profile" ''
    ${extraProfile}
  '';

in
stdenv.mkDerivation {
  name = "initrd";
  nativeBuildInputs = [ rsync cpio gzip ];
  buildCommand = ''
    root=root

    mkdir -p $root/etc
    rsync -a ${busybox-static}/ $root/
    find $root -type d -exec chmod +w {} ';'
    cp ${init} $root/init
    cp ${profile} $root/etc/profile

    ${extraBuild}

    (cd $root && find * -print0 | xargs -0r touch -h -d '@1')
    (cd $root && find * -print0 | sort -z | cpio -o -H newc -R +0:+0 --reproducible --null | ${compress} > $out)
  '';
}
