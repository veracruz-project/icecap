# This file is derived from
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/modules-closure.sh
#
# Copyright (c) 2020 Arm Limited
# Copyright (c) 2003-2020 Eelco Dolstra and the Nixpkgs/NixOS contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Given a kernel build (with modules in $kernel/lib/modules/VERSION),
# produce a module tree in $out/lib/modules/VERSION that contains only
# the modules identified by `rootModules', plus their dependencies.
# Also generate an appropriate modules.dep.

# TODO
# depmod: WARNING: could not open modules.order at /nix/store/...-modules-closure/lib/modules/5.4.0: No such file or directory
# depmod: WARNING: could not open modules.builtin at /nix/store/...-modules-closure/lib/modules/5.4.0: No such file or directory


{ lib, runCommand
, nukeReferences
, kmod
}:

{ kernel, firmware
, rootModules
, allowMissing ? false
}:

with lib;

runCommand "modules-closure" {
  nativeBuildInputs = [ nukeReferences kmod ];
  allowedReferences = [ "out" ];
  inherit allowMissing;
} ''
  version=$(cd ${kernel}/lib/modules && ls -d *)

  echo "kernel version is $version"

  # Determine the dependencies of each root module.
  closure=
  for module in ${concatStringsSep " " rootModules}; do
      echo "root module: $module"
      deps=$(
        modprobe --config no-config -d ${kernel} --set-version "$version" --show-depends "$module" \
          | sed 's/^insmod //'
      ) || if test -z "$allowMissing"; then exit 1; fi
      if [[ "$deps" != builtin* ]]; then
          closure="$closure $deps"
      fi
  done

  echo "closure:"
  mkdir -p "$out/lib/modules/$version"
  for module in $closure; do
      target=$(echo $module | sed "s^$NIX_STORE.*/lib/modules/^$out/lib/modules/^")
      if test -e "$target"; then continue; fi
      if test \! -e "$module"; then continue; fi # XXX: to avoid error with "cp builtin builtin"
      mkdir -p $(dirname $target)
      echo $module
      cp $module $target
      # If the kernel is compiled with coverage instrumentation, it
      # contains the paths of the *.gcda coverage data output files
      # (which it doesn't actually use...).  Get rid of them to prevent
      # the whole kernel from being included in the initrd.
      nuke-refs $target
      echo $target >> $out/insmod-list
  done

  mkdir -p $out/lib/firmware
  for module in $closure; do
      for i in $(modinfo -F firmware $module); do
          mkdir -p "$out/lib/firmware/$(dirname "$i")"
          echo "firmware for $module: $i"
          cp "${firmware}/lib/firmware/$i" "$out/lib/firmware/$i" 2>/dev/null || if test -z "$allowMissing"; then exit 1; fi
      done
  done

  depmod -b $out -a $version
''
