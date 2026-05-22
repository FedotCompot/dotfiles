#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$HOME/.cache/.bun/bin:$HOME/go/bin:$PATH"
