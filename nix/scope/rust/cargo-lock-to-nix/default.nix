{ runCommand, python3Packages, fetchCratesIOCrate, fetchGitCrate }:

cargoLock:

import (runCommand "Cargo.lock.nix" {
  nativeBuildInputs = [
    python3Packages.toml
  ];
} ''
  python3 ${./helper.py} < ${cargoLock} > $out
'') {
  inherit fetchCratesIOCrate fetchGitCrate;
}
