let
  system = builtins.currentSystem;

  src = builtins.fetchGit rec {
    url = "https://github.com/NixOS/nix.git";
    ref = "master";
    rev = "f4a9fb67da5bc55221be451556710dfacb39eda0";
  };

  nix = import src;

in
  nix.defaultPackage.${system}
