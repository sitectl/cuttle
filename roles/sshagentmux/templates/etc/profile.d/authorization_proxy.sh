# {{ ansible_managed }}

# Apparently in .profile and .rc context the parent pid changes when using backticks and eval, so work around it by dumping environment to a new file and souring it
AGENT_ENV=$(mktemp)
/usr/local/bin/sshagentmux --socket {{ sshagentmux.auth_socket }} > ${AGENT_ENV}
. ${AGENT_ENV}
rm ${AGENT_ENV}
