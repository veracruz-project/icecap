__icecap_shortcuts=./tmp/shortcuts.nix

alias n="nix-build ${__icecap_shortcuts} -j$(nproc) -A"
alias nn="nix-build --no-out-link ${__icecap_shortcuts} -j$(nproc) -A"
alias ne="nix-instantiate --eval ${__icecap_shortcuts} -j$(nproc) -A"
alias nes="nix-instantiate --eval --strict ${__icecap_shortcuts} -j$(nproc) -A"
alias r="./result/run"
alias rd="./result/run -d"

k() {
    remote="$1"
    ref="$2"
    short_rev=$(git rev-parse --short=32 "$ref")
    tag=icecap/keep/$short_rev
    git tag $tag $short_rev
    git push "$remote" $tag
}
