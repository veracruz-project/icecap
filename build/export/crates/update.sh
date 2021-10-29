set -e

here=$(dirname $0)

script=$(nix-build $here -A script)

eval $script
