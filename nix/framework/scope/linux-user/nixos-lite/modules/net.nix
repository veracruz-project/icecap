{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.net;

  udhcpcScript = pkgs.writeScript "udhcpc.sh" ''
    #!${config.build.extraUtils}/bin/sh
    if [ "$1" = bound ]; then
      ip address add "$ip/$mask" dev "$interface"
      if [ -n "$mtu" ]; then
        ip link set mtu "$mtu" dev "$interface"
      fi
      if [ -n "$staticroutes" ]; then
        echo "$staticroutes" \
          | sed -r "s@(\S+) (\S+)@ ip route add \"\1\" via \"\2\" dev \"$interface\" ; @g" \
          | sed -r "s@ via \"0\.0\.0\.0\"@@g" \
          | /bin/sh
      fi
      if [ -n "$router" ]; then
        ip route add "$router" dev "$interface" # just in case if "$router" is not within "$ip/$mask" (e.g. Hetzner Cloud)
        ip route add default via "$router" dev "$interface"
      fi
      if [ -n "$dns" ]; then
        rm -f /etc/resolv.conf
        for i in $dns; do
          echo "nameserver $dns" >> /etc/resolv.conf
        done
      fi
    fi
  '';

in {
  options = {

    net.interfaces = mkOption {
      default = {};
      type = types.unspecified;
    };

  };

  config = {

    initramfs.extraInitCommands = ''
      ${concatStrings (mapAttrsToList (interface: v: ''
        echo "setting up ${interface}..."
        ip link set ${interface} up
        ${optionalString (hasAttr "delayHack" v) ''
          # NOTE delaying for a few seconds (e.g. 5) seems to be necessary on the Raspberry Pi 4
          echo 'DELAY HACK: ${v.delayHack}'
          sleep ${v.delayHack}
        ''}
        ${if hasAttr "static" v then ''
          ip address add ${v.static} dev ${interface}
        '' else ''
          udhcpc --quit --now -i ${interface} -O staticroutes --script ${udhcpcScript}
        ''}
      '') cfg.interfaces)}
    '';

  };
}
