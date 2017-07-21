# (c) 2016, Gaetan Trellu (goldyfruit) <gaetan.trellu@incloudus.com>
# (c) 2014, Pierre-Yves KERVIEL <pierreyves.kerviel@orange.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.
#
# inidata is used to manage ini
#
# YAML example:
#   glance_api_config:
#      oslo_messaging_rabbit:
#        amqp_durable_queues: 'true'
#        rabbit_host: 172.0.0.100
#        rabbit_port: 5672
#      paste_deploy:
#        flavor: keystone
#
# Task example:
#   - name: Set glance-api configuration
#     ini_file:
#       dest=/etc/glance/glance-registry.conf
#       section={{ item.0 }}                   # oslo_messaging_rabbit
#       option={{ item.1 }}                    # rabbit_host
#       value={{ item.2 }}                     # 172.0.0.100
#     with_inidata: "{{ glance_api_config }}"

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError

class LookupModule(LookupBase):

    def run(self, terms, inject=None, **kwargs):

        if not isinstance(terms, dict):
            raise AnsibleError("inidata lookup expects a dictionnary, got '%s'" % terms)

        ret = []
        for item0 in terms:
            try:
                if not isinstance(terms[item0], dict):
                    raise AnsibleError("inidata lookup expects a dictionary, got '%s'" % terms[item0])
                for item1 in terms[item0]:
                    ret.append((item0, item1, terms[item0][item1]))
            except Exception as e:
                raise AnsibleError(e)
        return ret
