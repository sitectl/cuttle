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

UPSTART_TEMPLATE = """
start on {{ start_on }}
stop on {{ stop_on }}

{% if description -%}
description {{ description }}
{% endif -%}

{% if envs -%}
{% for env in envs %}
env {{ env }}
{% endfor %}
{% endif -%}

{% if prestart_script -%}
pre-start script
    {{ prestart_script }}
end script
{% endif -%}

{% if respawn -%}
respawn
{% endif -%}

{% if expect -%}
expect {{ expect }}
{% endif -%}

exec start-stop-daemon --start --chuid {{ user }} {{ pidfile }} --exec {{ cmd }} {{ args }}
"""

def main():

    module = AnsibleModule(
        argument_spec=dict(
            name=dict(default=None, required=True),
            cmd=dict(default=None, required=True),
            args=dict(default=None),
            user=dict(default=None, required=True),
            config_dirs=dict(default=None),
            config_files=dict(default=None),
            description=dict(default=None),
            expect=dict(default=None),
            envs=dict(default=None, required=False, type='list'),
            state=dict(default='present'),
            start_on=dict(default='runlevel [2345]'),
            stop_on=dict(default='runlevel [!2345]'),
            prestart_script=dict(default=None),
            respawn=dict(default=True),
            path=dict(default=None),
            pidfile=dict(default=None)
        )
    )

    try:
        changed = False
        service_path = None
        if not module.params['path']:
            service_path = '/etc/init/%s.conf' % module.params['name']
        else:
            service_path = module.params['path']

        symlink = os.path.join('/etc/init.d/', module.params['name'])

        if module.params['state'] == 'absent':
            if os.path.exists(service_path):
                os.remove(service_path)
                changed = True
            if os.path.exists(symlink):
                os.remove(symlink)
                changed = True
            if not changed:
                module.exit_json(changed=False, result="ok")
            else:
                module.exit_json(changed=True, result="changed")

        pidfile = ''
        if module.params['pidfile'] and len(module.params['pidfile']):
            pidfile = '--make-pidfile --pidfile %s' % module.params['pidfile']

        args = ''
        if module.params['args'] or module.params['config_dirs'] or \
           module.params['config_files']:
            args = '-- '
            if module.params['args']:
                args += module.params['args']

            if module.params['config_dirs']:
                for directory in module.params['config_dirs'].split(','):
                    args += '--config-dir %s ' % directory

            if module.params['config_files']:
                for filename in module.params['config_files'].split(','):
                   args += '--config-file %s ' % filename

        template_vars = module.params
        template_vars['pidfile'] = pidfile
        template_vars['args'] = args

        env = Environment().from_string(UPSTART_TEMPLATE)
        rendered_service = env.render(template_vars)

        if os.path.exists(service_path):
            file_hash = md5(open(service_path, 'rb').read()).hexdigest()
            template_hash = md5(rendered_service).hexdigest()
            if file_hash == template_hash:
                module.exit_json(changed=False, result="ok")

        with open(service_path, "w") as fh:
            fh.write(rendered_service)

        if not os.path.exists(symlink):
            os.symlink('/lib/init/upstart-job', symlink)

        module.exit_json(changed=True, result="created")
    except Exception as e:
        formatted_lines = traceback.format_exc()
        module.fail_json(msg="creating the service failed: %s" % (str(e)))

# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *
main()
