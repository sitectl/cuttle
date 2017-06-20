#!/bin/bash

# {{ ansible_managed }}

{% for _arch in item.value.archs %}
reposync -c /etc/yum/yum.conf --repoid="{{ item.key }}-{{ (item.value.release|default('el/7')) | replace('/','') }}-{{ _arch.arch }}" --download_path="{{ yum_mirror.path }}/mirror/{{ item.key }}/{{ item.value.release|default('el/7') }}/{{ _arch.basearch|default(_arch.arch) }}" --arch="{{ _arch.arch }}" --norepopath
yum --disablerepo=* --enablerepo="{{ item.key }}-{{ (item.value.release|default('el/7')) | replace('/','') }}-{{ _arch.arch }}" makecache
curl -Lso /var/cache/yum/{{ item.key }}-{{ (item.value.release|default('el/7')) | replace('/','') }}-{{ _arch.arch }}/repomd.xml.asc {{ _arch.url|default(item.value.url) }}/{{ item.value.release|default('el/7') }}/{{ _arch.basearch|default(_arch.arch) }}/repodata/repomd.xml.asc
ln -sfn /var/cache/yum/{{ item.key }}-{{ (item.value.release|default('el/7')) | replace('/','') }}-{{ _arch.arch }} {{ yum_mirror.path }}/mirror/{{ item.key }}/{{ item.value.release|default('el/7') }}/{{ _arch.basearch|default(_arch.arch) }}/repodata

{% endfor %}
