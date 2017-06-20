#!/usr/bin/python

DOCUMENTATION = '''
---
module: binary
version_added: 0.1
short_description: outputs binary files safely
description:
    - Will safely output base64 encoded binaries.
options:
  base64:
    description:
      - Base64 encoded binary file
    required: true
  dest:
    description:
      - Path of the file to write to
    required: true
  owner:
    description:
      - owner of the file
    required: false
  group:
    description:
      - group of the file
    required: false
'''

EXAMPLES = '''
- binary: base64="{{ my_base64_binary }}" dest=/var/lib/secret.key
'''

import base64
import md5
import os
import pwd
import grp


def main():
    conf = AnsibleModule(
        argument_spec = dict(
            base64  = dict(required=True),
            dest = dict(required=True),
            owner = dict(required=False, default=None),
            group = dict(required=False, default=None),
        )
    )

    binary = base64.b64decode(conf.params['base64'])
    dest = conf.params['dest']
    md5sum = md5.md5(binary).hexdigest()
    current_md5sum = None
    changed = False
    diff = {'before': {}, 'after': {}}

    if os.path.exists(dest):
      with open(dest, 'rb') as f:
        current_md5sum = md5.md5(f.read()).hexdigest()

    if current_md5sum != md5sum:
      with open(dest, 'wb') as f:
        f.write(binary)
        changed = True
        diff['before']['md5'] = current_md5sum
        diff['after']['md5'] = md5sum

    if conf.params['owner']:
      uid = pwd.getpwnam(conf.params['owner']).pw_uid
      current_uid = os.stat(dest).st_uid
      if uid != current_uid:
        os.chown(dest, uid, -1)
        changed = True
        diff['before']['owner'] = pwd.getpwuid(current_uid).pw_name
        diff['after']['owner'] = conf.params['owner']

    if conf.params['group']:
      gid = grp.getgrnam(conf.params['group']).gr_gid
      current_gid = os.stat(dest).st_gid
      if gid != current_gid:
        os.chown(dest, -1, gid)
        changed = True
        diff['before']['group'] = grp.getgrgid(current_gid).gr_name
        diff['after']['group'] = conf.params['group']

    conf.exit_json(changed=changed, result=diff)


# import site snippets
from ansible.module_utils.basic import *
main()
