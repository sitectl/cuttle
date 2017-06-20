# -*- coding: utf-8 -*-
# (c) 2014, Craig Tracey <craigtracey@gmail.com>
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

import collections
import os
import yaml

from ansible.constants import DEFAULTS, get_config, load_config_file


def deep_update_dict(d, u):
    for k, v in u.iteritems():
        if isinstance(v, collections.Mapping):
            r = deep_update_dict(d.get(k, {}), v)
            d[k] = r
        else:
            d[k] = u[k]
    return d


class VarsModule(object):

    def __init__(self, inventory):
        self.inventory = inventory
        self.inventory_basedir = inventory.basedir()

    def _get_defaults(self):
        p, cfg_path = load_config_file()
        defaults_file = get_config(p, DEFAULTS, 'var_defaults_file',
                                   'ANSIBLE_VAR_DEFAULTS_FILE', None)
        print "Using defaults.yml: %s" % defaults_file
        if not defaults_file:
            return None

        ursula_env = os.environ.get('URSULA_ENV', '')
        defaults_path = os.path.join(ursula_env, defaults_file)
        if os.path.exists(defaults_path):
            with open(defaults_path) as fh:
                return yaml.safe_load(fh)
        return None

    def run(self, host, vault_password=None):

        default_vars = self._get_defaults()
        # This call to the variable_manager will get the variables of
        # a given host, with the variable precedence already sorted out.
        # This references some "private" like objects and may need to be
        # adjusted in the future if/when this all gets overhauled.
        # See also https://github.com/ansible/ansible/pull/17067
        inv_vars = self.inventory._variable_manager.get_vars(
                                 loader=self.inventory._loader, host=host)
        if default_vars:
            return deep_update_dict(default_vars, inv_vars)
        return inv_vars
