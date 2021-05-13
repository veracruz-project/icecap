let
  system = builtins.currentSystem;

  src = builtins.fetchGit rec {
    url = "https://gitlab.com/arm-research/security/icecap/nix.git";
    ref = "refs/tags/icecap/keep/${builtins.substring 0 32 rev}";
    rev = "f4a9fb67da5bc55221be451556710dfacb39eda0";
  };

  nix = import src;

in
  nix.defaultPackage.${system}
