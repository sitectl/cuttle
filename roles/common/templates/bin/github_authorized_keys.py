#!/usr/bin/python

import sys
import requests
import json


if len(sys.argv) == 2:
    ssh_user = sys.argv[1]

    user_url = "{{ common.ssh.github_authorized_keys.api_url }}/users/%s" % ssh_user
    key_url = "%s/keys" % user_url
    api_user = '{{ common.ssh.github_authorized_keys.api_user }}'
    api_key = '{{ common.ssh.github_authorized_keys.api_pass }}'

    if api_user and api_key:
        user_info = requests.get(user_url,auth=(api_user, api_key))
    else:
        user_info = requests.get(user_url)
    if(user_info.ok):
        user = json.loads(user_info.content)
        if not user['suspended_at']:
            if api_user and api_key:
                myResponse = requests.get(key_url,auth=(api_user, api_key))
            else:
                myResponse = requests.get(key_url)
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
