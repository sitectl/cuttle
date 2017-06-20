#!/usr/bin/python
#coding: utf-8 -*-

# (c) 2013-2014, Christian Berendt <berendt@b1-systems.de>
#
# This site is free software: you can redistribute it and/or modify
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

DOCUMENTATION = '''
---
module: apache2_site
version_added: 1.6
short_description: enables/disables a site for the Apache2 webserver
description:
   - Enables or disables a specified site for the Apache2 webserver.
options:
   name:
     description:
        - name of the site to enable/disable
     required: true
   state:
     description:
        - indicate the desired state of the resource
     choices: ['enabled', 'disabled', 'present', 'absent']
     default: enabled

'''

EXAMPLES = '''
# enables the Apache2 site "default"
- apache2_site: state=enabled name=default

# disables the Apache2 site "default"
- apache2_site: state=disabled name=default
'''

import re

def _disable_site(site):
    name = site.params['name']
    a2dissite_binary = site.get_bin_path("a2dissite")
    result, stdout, stderr = site.run_command("%s %s" % (a2dissite_binary, name))

    if re.match(r'.*' + name + r' already disabled.*', stdout, re.S):
        site.exit_json(changed = False, result = "Success")
    elif result != 0:
        site.fail_json(msg="Failed to disable site %s: %s" % (name, stdout))
    else:
        site.exit_json(changed = True, result = "Disabled")

def _enable_site(site):
    name = site.params['name']
    a2dissite_binary = site.get_bin_path("a2ensite")
    result, stdout, stderr = site.run_command("%s %s" % (a2dissite_binary, name))

    if re.match(r'.*' + name + r' already enabled.*', stdout, re.S):
        site.exit_json(changed = False, result = "Success")
    elif result != 0:
        site.fail_json(msg="Failed to enable site %s: %s" % (name, stdout))
    else:
        site.exit_json(changed = True, result = "Enabled")

def main():
    site = AnsibleModule(
        argument_spec = dict(
            name  = dict(required=True),
            state = dict(default='enabled', choices=['disabled', 'enabled', 'present', 'absent'])
        ),
    )

    if site.params['state'] == 'enabled' or site.params['state'] == 'present':
        _enable_site(site)

    if site.params['state'] == 'disabled' or site.params['state'] == 'absent':
        _disable_site(site)

# import site snippets
from ansible.module_utils.basic import *
main()
