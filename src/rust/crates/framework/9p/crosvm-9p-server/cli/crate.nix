{ mkBin, localCrates }:

mkBin {
  nix.name = "crosvm-9p-server-cli";
  nix.local.dependencies = with localCrates; [
    crosvm-9p-server
  ];
  dependencies = {
    getopts = "*";
    libc = "*";
    log = "*";
    env_logger = "*";
  };
}
