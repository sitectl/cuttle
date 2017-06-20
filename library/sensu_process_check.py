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

def main():

    module = AnsibleModule(
        argument_spec=dict(
            service=dict(default=None, required=True),
            short_service_name=dict(required=False),
            warn_over=dict(default=15, required=False),
            crit_over=dict(default=30, required=False),
            interval=dict(default=30, required=False),
            occurrences=dict(default=2, required=False),
            service_owner=dict(required=False, default=None),
            handlers=dict(required=False, default='default'),
            tags=dict(required=False, type='list'),
            dependencies=dict(required=False, type='list'),
            check_dir=dict(default='/etc/sensu/conf.d/checks', required=False),
            state=dict(default='present', required=False, choices=['present','absent'])
        )
    )

    if module.params['state'] == 'present':
        try:
            changed = False
            if not module.params['short_service_name']:
                short_service_name = os.path.basename(module.params['service'])
            check_path = "%s/%s-service.json" % ( module.params['check_dir'], short_service_name)
            command = "check-procs.rb -p %s -w %s -c %s -W 1 -C 1" % (module.params['service'], module.params['warn_over'], module.params['crit_over'] )
            notification = "unexpected number of %s processes" % ( module.params['service'] )
            check=dict({
                'checks': {
                    short_service_name: {
                        'command': command,
                        'standalone': True,
                        'handlers': [ 'default' ],
                        'interval': int(module.params['interval']),
                        'notification': notification,
                        'occurrences':  int(module.params['occurrences']),
                        'tags': module.params['tags'],
                        'dependencies': module.params['dependencies']
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
