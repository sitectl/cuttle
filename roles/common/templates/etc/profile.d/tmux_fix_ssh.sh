fixssh() {
  if [ -n "$TMUX" ]; then
    echo "fixing tmux ssh-agent"
    eval $(tmux show-env    \
        |sed -n 's/^\(SSH_[^=]*\)=\(.*\)/export \1="\2"/p')
  else
    echo "not in tmux, something else is broken."
  fi
}

