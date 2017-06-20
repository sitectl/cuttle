#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright 2014, Blue Box Group, Inc.
# Copyright 2014, Craig Tracey <craigtracey@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import traceback

from hashlib import md5
from jinja2 import Environment

def main():

    module = AnsibleModule(
        argument_spec=dict(
            name=dict(default=None, required=True),
            use_sudo=dict(required=False, type='bool', default=False),
            plugin=dict(default=None, required=True),
            args=dict(default='', required=False),
            handlers=dict(required=False, default='metrics'),
            service_owner=dict(required=False, default=None),
            check_dir=dict(default='/etc/sensu/conf.d/checks', required=False),
            prefix=dict(default='', required=False),
            interval=dict(default=60, required=False),
            state=dict(default='present', required=False, choices=['present','absent'])
        )
    )

    if module.params['state'] == 'present':
        try:
            changed = False
            check_path = '%s/%s.json' % (module.params['check_dir'], module.params['name'])
            command = '%s %s' % ( module.params['plugin'], module.params['args'] )
            if module.params['prefix']:
                command = '%s %s' % (module.params['prefix'], command)
            if module.params['use_sudo']:
                command = "sudo %s" % (command)
            check=dict({
                'checks': {
                    module.params['name']: {
                        'type': 'metric',
                        'command': command,
                        'standalone': True,
                        'interval': int(module.params['interval']),
                        'handlers': module.params['handlers'].split(','),
                        'service_owner': module.params['service_owner']
                    }
                }
            })

            if os.path.isfile(check_path):
                with open(check_path) as fh:
                    if json.load(fh) == check:
                        module.exit_json(changed=False, result="ok")
                    else:
                        with open(check_path, "w") as fh:
                            fh.write(json.dumps(check, indent=4))
                        module.exit_json(changed=True, result="changed")
            else:
                with open(check_path, "w") as fh:
                    fh.write(json.dumps(check, indent=4))
                module.exit_json(changed=True, result="created")
        except Exception as e:
            formatted_lines = traceback.format_exc()
            module.fail_json(msg="creating the check failed: %s %s" % (e,formatted_lines))

    else:
        try:
            changed = False
            check_path = '%s/%s.json' % (module.params['check_dir'], module.params['name'])
            if os.path.isfile(check_path):
                os.remove(check_path)
                module.exit_json(changed=True, result="changed")
            else:
                module.exit_json(changed=False, result="ok")
        except Exception as e:
            formatted_lines = traceback.format_exc()
            module.fail_json(msg="removing the check failed: %s %s" % (e,formatted_lines))

# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *
main()
