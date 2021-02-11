alias n='nix-build -A'
alias nn='nix-build --no-out-link -A'
alias ne='nix-instantiate --eval . -A'
alias nes='nix-instantiate --eval --strict . -A'
alias r='./result/run'

k() {
    remote="$1"
    ref="$2"
    short_rev=$(git rev-parse --short=32 "$ref")
    tag=icecap/keep/$short_rev
    git tag $tag $short_rev
    git push "$remote" $tag
}
