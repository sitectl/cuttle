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

INIT_CONFIG_TEMPLATE = """
[Unit]
{% if description -%}
Description={{ description }}
{% endif %}

{% if default_deps -%}
DefaultDependencies={{ default_deps }}
{% endif %}

{% if after -%}
After={{ after }}
{% else -%}
After=network.target syslog.target
{% endif %}

{% if before -%}
Before={{ before }}
{% endif %}

{% if wants -%}
Wants={{ wants }}
{% endif %}

[Install]
{% if wanted_by -%}
WantedBy={{ wanted_by }}
{% endif %}
##### Alias={{ name }}.service

[Service]
{% if service_type -%}
Type={{ service_type }}
{% endif %}

{% if pidfile -%}
PIDFile={{ pidfile }}
{% endif %}

{% if env_vars -%}
Environment={{ env_vars | join(' ') }}
{% endif %}
{% if environment_file -%}
EnvironmentFile={{ environment_file }}
{% endif %}

{% if chdir -%}
WorkingDirectory={{ chdir }}
{% endif %}

{% if restart -%}
Restart={{ restart }}
{% endif %}

# Start main service
ExecStart={{ cmd }} {{ args }}

{% if prestart_script -%}
ExecStartPre={{ prestart_script }}
{% endif %}

#ExecStop=

#ExecStopPost=

{% if reload_script -%}
ExecReload={{ reload_script }}
{% endif %}

{% if user -%}
User={{ user }}
{% endif %}
{% if group -%}
Group={{ group }}
{% endif %}

TimeoutStartSec=120
TimeoutStopSec=120

"""

def main():

    module = AnsibleModule(
        argument_spec=dict(
            after=dict(default=None),
            args=dict(default=None),
            before=dict(default=None),
            chdir=dict(default=None),
            cmd=dict(default=None, required=True),
            config_dirs=dict(default=None),
            config_files=dict(default=None),
            default_deps=dict(default=None),
            description=dict(default=None),
            env_vars=dict(default=None, type='list'),
            group=dict(default=None),
            name=dict(default=None, required=True),
            path=dict(default=None),
            pidfile=dict(default=None),
            prestart_script=dict(default=None),
            reload_script=dict(default=None),
            restart=dict(default="on-failure"),
            service_type=dict(default="simple"),
            state=dict(default='present'),
            user=dict(default=None),
            wanted_by=dict(default=None),
            wants=dict(default=None)
        )
    )

    try:
        changed = False
        service_path = None
        if not module.params['path']:
            service_path = '/etc/systemd/system/%s.service' % module.params['name']
        else:
            service_path = module.params['path']

        if module.params['state'] == 'absent':
            if os.path.exists(service_path):
                os.remove(service_path)
                changed = True
            if not changed:
                module.exit_json(changed=False, result="ok")
            else:
                os.system('systemctl daemon-reload')
                module.exit_json(changed=True, result="changed")

        args = ' '
        if module.params['args'] or module.params['config_dirs'] or \
           module.params['config_files']:
            if module.params['args']:
                args += module.params['args']

            if module.params['config_dirs']:
                for directory in module.params['config_dirs'].split(','):
                    args += '--config-dir %s ' % directory

            if module.params['config_files']:
                for filename in module.params['config_files'].split(','):
                   args += '--config-file %s ' % filename

        template_vars = module.params
        template_vars['args'] = args

        env = Environment().from_string(INIT_CONFIG_TEMPLATE)
        rendered_service = env.render(template_vars)

        if os.path.exists(service_path):
            file_hash = md5(open(service_path, 'rb').read()).hexdigest()
            template_hash = md5(rendered_service).hexdigest()
            if file_hash == template_hash:
                module.exit_json(changed=False, result="ok")

        with open(service_path, "w") as fh:
            fh.write(rendered_service)
        os.system('systemctl daemon-reload')
        module.exit_json(changed=True, result="created")
    except Exception as e:
        formatted_lines = traceback.format_exc()
        module.fail_json(msg="creating the service failed: %s" % (str(e)))

# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *

main()
