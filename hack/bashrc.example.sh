__icecap_default_expression=${parameter:-./tmp/shortcuts.nix}

alias n="nix-build ${__icecap_default_expression} -A"
alias nn="nix-build --no-out-link ${__icecap_default_expression} -A"
alias ne="nix-instantiate --eval ${__icecap_default_expression} -A"
alias nes="nix-instantiate --eval --strict ${__icecap_default_expression} -A"

alias r="./result/run"
alias b='./result/debug/icecap-show-backtrace'

k() {
    remote="${1:-origin}"
    ref="${2:-HEAD}"
    short_rev=$(git rev-parse --short=32 "$ref")
    tag=icecap/keep/$short_rev
    git tag $tag $short_rev
    git push "$remote" $tag
}
