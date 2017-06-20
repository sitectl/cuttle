#!/bin/sh
#
# {{ ansible_managed }}

DEVPI={{ pypi_mirror.virtualenv }}/bin/devpi

# use localhost devpi
${DEVPI} use http://127.0.0.1:4040

# Login as root
${DEVPI} login root --password='{{ pypi_mirror.root_password }}'

# modify users in an idempotent way
{% for user in pypi_mirror.users %}
{% if user.disabled|default("False")|bool %}
${DEVPI} user --delete {{ user.username }}
{% else %}
if ${DEVPI} user -l | egrep  "^test$"; then
  # ensure password is correct, not idempotent, but pretty safe.
    ${DEVPI} user -m {{ user.username }} password='{{ user.password }}'
else
  # create user with password
    ${DEVPI} user -c {{ user.username }} password='{{ user.password }}'
fi
{% endif %}
{% endfor %}

# Create user indexes if they do not exist
{% for repo,location in pypi_mirror.repos.iteritems() %}
if ! devpi use -l | grep -e '^{{ location.username }}/{{ location.index }}\s'; then
    devpi index -c {{ location.username }}/{{ location.index }} type=mirror mirror_cache_expiry={{ location.mirror.cache_expiry }} mirror_url={{ location.mirror.url }}/{{ repo }}/pypi/simple
fi
{% endfor %}

# logoff
${DEVPI} logoff
