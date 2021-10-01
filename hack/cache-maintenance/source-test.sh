set -eu

here="$(dirname "$0")"

export CURRENT_REV="$(git show -s --format=%H)"

nix-build "$here/source-test.nix" -A test
