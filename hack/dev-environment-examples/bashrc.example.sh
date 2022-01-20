__icecap_default_expression=${__icecap_default_expression:-./tmp/shortcuts.nix}

alias n="nix-build ${__icecap_default_expression} -A"
alias nn="nix-build --no-out-link ${__icecap_default_expression} -A"
alias ne="nix-instantiate --eval ${__icecap_default_expression} -A"
alias nes="nix-instantiate --eval --strict ${__icecap_default_expression} -A"

alias ns='nix-shell'

alias r="./result/run"
alias b='./result/debug/icecap-show-backtrace'

alias mt='miniterm.py /dev/ttyUSB0 115200 --raw --eol LF'

alias k='git-icecap-keep'
