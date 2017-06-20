#!/usr/bin/python

import sys
import requests
import json


if len(sys.argv) == 2:
    ssh_user = sys.argv[1]

    user_url = "{{ common.ssh.ghe_authorized_keys.api_url }}/users/%s" % ssh_user
    key_url = "%s/keys" % user_url
    api_user = '{{ common.ssh.ghe_authorized_keys.api_user }}'
    api_key = '{{ common.ssh.ghe_authorized_keys.api_pass }}'

    user_info = requests.get(user_url,auth=(api_user, api_key))
    if(user_info.ok):
        user = json.loads(user_info.content)
        if not user['suspended_at']:
            myResponse = requests.get(key_url,auth=(api_user, api_key))
            if(myResponse.ok):
                keys = json.loads(myResponse.content)
                for key in keys:
                      print key['key']
            else:
                print "user %s is disabled" % ssh_user
                raise
else:
    print "you must provide a username"
    raise
