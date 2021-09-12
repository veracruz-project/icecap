set -eu

here="$(dirname "$0")"

export CURRENT_REV="$(git show -s --format=%H)"
export CURRENT_REF="$(git branch --show-current)"

nix-build "$here/source-test.nix" -A test
