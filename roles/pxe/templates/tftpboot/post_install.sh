#!/bin/bash
#
# {{ ansible_managed }}

{% if item.mirror_http_proxy|default(pxe.mirror_http_proxy) %}
export http_proxy={{ item.mirror_http_proxy|default(pxe.mirror_http_proxy) }}
export https_proxy={{ item.mirror_http_proxy|default(pxe.mirror_http_proxy) }}
export no_proxy=127.0.0.1
{% endif %}

echo 'UseDNS no' >> /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

OUMASK=$( umask 0 )
mkdir -p /home/blueboxadmin/.ssh
cat <<EOF > /home/blueboxadmin/.ssh/authorized_keys
{{ pxe.ssh_pub_keys|join('\n') }}
EOF
chown -R blueboxadmin:blueboxadmin /home/blueboxadmin/.ssh
echo "blueboxadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/blueboxadmin
umask ${OUMASK}


# strip out non-mirror sources
sed -i '/http:\/\/security\.ubuntu\.com/d' /etc/apt/sources.list

echo "$(date): upgrading linux" > /root/post_install.log

apt-get update >> /root/post_install.log
apt-get -y dist-upgrade >> /root/post_install.log

{% if item.network is defined -%}
echo $(date): writing out network config >> /root/post_install.log
cat <<EOF > /etc/network/interfaces
{{ item.network }}
EOF
{% else %}
echo $(date): using default network >> /root/post_install.log
{% endif -%}

echo $(date): finished post-install >> /root/post_install.log

APT_CONF="/etc/apt/apt.conf"
if [ -e "$APT_CONF" ]; then
    rm -f $APT_CONF
fi
