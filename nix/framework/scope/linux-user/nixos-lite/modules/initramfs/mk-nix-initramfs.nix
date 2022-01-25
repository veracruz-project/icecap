{ runCommand, closureInfo
, cpio, gzip
}:

{ content
, compress ? "gzip -9n"
, passthru ? {}
}:

let
  closure = closureInfo {
    rootPaths = [
      content
    ];
  };

in runCommand "initramfs.gz" {
  nativeBuildInputs = [ cpio gzip ];
  inherit passthru;
} ''
  tmp_cpio=$NIX_BUILD_TOP/tmp.cpio
  sink="cpio --create -H newc -R +0:+0 --reproducible --null --file $tmp_cpio"
  find ${content} -printf '%P\0' | sort -z | $sink -D ${content}
  printf 'nix\0nix/store\0' | $sink -D / --append
  find $(cat ${closure}/store-paths | grep -v ${content}) -print0 | sed -z 's,^/,,' | sort -z | $sink -D / --append
  ${compress} < $tmp_cpio > $out
''
