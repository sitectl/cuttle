#!/bin/bash
{% if common.shell_customization.git_prompt|bool %}
prompt_git() {
  local branchName='';

  # Check if the current directory is in a Git repository.
  if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

    # Get the short symbolic ref.
    # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
    # Otherwise, just give up.
    branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
        git rev-parse --short HEAD 2> /dev/null || \
        echo '(unknown)')";

    echo -e " [${1}${branchName}]";
  else
    return;
  fi;
}
{% endif %}
