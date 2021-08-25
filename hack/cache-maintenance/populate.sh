set -eu

here="$(dirname "$0")"
host="$1"

drv=$(nix-instantiate "$here/populate.nix")
nix-store --realise $drv
nix-copy-closure --include-outputs --to "$host" $drv
