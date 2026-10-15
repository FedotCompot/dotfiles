#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$HOME/.cache/.bun/bin:$HOME/go/bin:$PATH"
. "$HOME/.cargo/env"

# Hermes Agent command
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
