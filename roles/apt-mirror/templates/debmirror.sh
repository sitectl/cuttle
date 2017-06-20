#!/usr/bin/env bash

{% for key, value in (apt_mirror.debmirror.repositories|combine(apt_mirror.debmirror.distros)).iteritems() %}
{% if value.enabled is not defined or value.enabled|bool %}
debmirror -v --keyring /etc/apt/trusted.gpg \
          --method={{ value.method }} {% if value.method != "rsync" %} --rsync-extra=none {% endif %} \
          {% if value.exclude_regex is defined %} --exclude='{{ value.exclude_regex }}' {% endif %} \
          {% if value.include_regex is defined %} --include='{{ value.include_regex }}' {% endif %} \
          {% if value.upstream_username is defined %} --user='{{ value.upstream_username }}' {% endif %} \
          {% if value.upstream_password is defined %} --passwd='{{ value.upstream_password }}' {% endif %} \
          {% if value.ignore_missing_release is defined and value.ignore_missing_release|bool %} --ignore-missing-release {% endif %} \
          --arch {{ value.arch }} --no-source --getcontents \
          --host {{ value.host }} --root {{ value.path }} \
          --dist {{ value.distributions }} \
          --section {{ value.sections }} \
          {{ apt_mirror.path }}/mirror/{{ key }}

{% if value.download_files is defined %}
{% for file in value.download_files %}
curl -o {{ apt_mirror.path }}/mirror/{{ key }}/{{ file }} {{ value.method }}://{{ value.host }}/{{ value.path }}/{{ file }}
{% endfor %}
{% endif %}

{% endif %}
{% endfor %}
