#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:/home/fedot/.cache/.bun/bin:/home/fedot/go/bin:$PATH"
