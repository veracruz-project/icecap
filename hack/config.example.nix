{ config, lib, pkgs, ... }:

let

  nix-bash-completions =
    let
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/hedning/nix-bash-completions/e6db3081fe1f221470a26e345a96855e5f09ddec/_nix";
        sha256 = "sha256-T+L7cNjuh+MBmyZl+4IA7jQQegpi/L9cgbQmPB4taNw=";
      };
    in pkgs.runCommand "nix-bash-completions" {} ''
      commands=$(
        function complete() { shift 2; echo "$@"; }
        shopt -s extglob
        source ${src}
      )
      install -D -T ${src} $out/share/bash-completion/completions/_nix
      cd $out/share/bash-completion/completions
      for c in $commands; do
        ln -s _nix $c
      done
    '';

  bash-complete-alias = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/cykerway/complete-alias/4fcd018faa9413e60ee4ec9f48ebeac933c8c372/complete_alias";
    sha256 = "sha256-klo2tWCUyg5s6GrrxPdSSDjF6pz6E1lBeiCLu3A/4cc=";
  };

in
{

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    sandbox-fallback = false
    experimental-features = nix-command
  '';
  nix.binaryCaches = [
    http://52.214.93.220:5000
  ];
  nix.binaryCachePublicKeys = [
    "icecap:j+jQQU4VWcGmre43aPtCt1GNfLmtO2IMKoZ1MsHOmVY="
  ];

  environment.systemPackages = with pkgs; [
    git gnumake
    rsync screen python3Packages.pyserial
    nix-bash-completions
  ];

  programs.bash.interactiveShellInit = ''
    . ${bash-complete-alias}

    . ${./bashrc.example.sh}

    complete -F _complete_alias n
    complete -F _complete_alias nn
    complete -F _complete_alias ne
    complete -F _complete_alias nes
  '';

}
