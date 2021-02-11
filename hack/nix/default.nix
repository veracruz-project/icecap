let
  system = builtins.currentSystem;

  src = builtins.fetchGit rec {
    url = "https://gitlab.com/arm-research/security/icecap/nix.git";
    ref = "refs/tags/icecap/keep/${builtins.substring 0 32 rev}";
    rev = "550e11f077ae508abde5a33998a9d4029880e7b2";
  };

  nix = import src;

in
  nix.defaultPackage.${system}
