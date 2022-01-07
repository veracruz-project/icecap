# Building without Docker

If you want to build IceCap without Docker, the only requirement is
[Nix](https://nixos.org/manual/nix/stable/).  IceCap depends on features
currently present only in unstable versions of Nix since `2.4pre20200407`.  Here
are a few ways to use such a version:

- You could use
  [https://github.com/nspin/minimally-invasive-nix-installer/](https://github.com/nspin/minimally-invasive-nix-installer/).
  This is what the Docker solution uses.
- If you are using NixOS, you could set `nix.package = pkgs.nixUnstable`.  See
  [../hack/config.example.nix](../hack/config.example.nix) for an examples NixOS
  module which sets up a complete development environment for IceCap.
- If you already have Nix installed, you could use the output of `nix-build
  ./nixpkgs -A nixUnstable`. However, if your Nix installation is multi-user,
  then beware that a version mismatch between your Nix frontend and daemon can
  cause problems for some version combinations.
