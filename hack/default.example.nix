let
  topBase = import ./nix;

  top = topBase.override (args: args // {
    overlays = args.overlays ++ (
      let scratch = ./scratch/overlay.nix;
      in with topBase.lib; optional (pathExists scratch) (import scratch)
    );
  });

in top.none.lib.fix (self: top.none // top.none.icecap // top.none.instances // top // (with self; {
  b = buildPackages;
  v = virt;
  r = rpi4;
  d = dev;
  l = linux;
}))

/*

$ cat ./scratch/overlay.nix
self: super: with self;

let
in {

  scratch = lib.makeScope icecap.newScope (icecap.callPackage ./scope.nix {});

}

$ cat ./scratch/scope.nix
{ foo, bar
}:

self: with self;

let
in {

  baz = {};

}

*/
