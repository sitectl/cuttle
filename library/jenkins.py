#!/usr/bin/python

DOCUMENTATION = '''
---
module: jenkins_safe_restart
version_added: 0.1
short_description: restarts jenkins safely
description:
    - Will restart a jenkins server, allowing jobs to finish, and waiting for the server to fully start up before continuing.
options:
  task:
    description:
      - The task to perform.
    choices:
      - wait_for_startup
      - restart
      - install_plugin
    required: true
  url:
    description:
      - URL of the jenkins server
    required: true
  username:
    description:
      - username for access
    required: false
  password:
    description:
      - password for access
    required: false
  password:
    description:
      - password for access
    required: false
  plugin:
    description:
      - plugin to install
    required: false
  version:
    description:
      - plugin version
    required: false
  shutdown_check_delay:
    description:
      - seconds to delay between checking for complete shutdown
    required: false
'''

EXAMPLES = '''
# safely restart a running jenkins instance
- jenkins: url=http://127.0.0.1:8080/ username=admin password=admnin123 task=restart
'''

import base64
import time
import urllib2
import os
from ansible.module_utils.urls import *


def _get_installed_plugin_version(plugin):
  path = '/var/lib/jenkins/plugins/%s/META-INF/MANIFEST.MF' % plugin
  if os.path.exists(path):
    version_line = [l for l in open(path, 'r').readlines() if l.startswith('Plugin-Version')][0]
    return version_line.split(': ')[1].strip()


def main():
    conf = AnsibleModule(
        argument_spec = dict(
            url  = dict(required=True),
            task = dict(
              required=True,
              choices=['restart', 'wait_for_startup', 'install_plugin']),
            username = dict(required=False, default=None),
            password = dict(required=False, default=None),
            plugin = dict(required=False, default=None),
            version = dict(required=False, default="latest"),
            plugin_install_retries = dict(required=False, default=5),
            plugin_install_timeout = dict(required=False, default=10),
            shutdown_check_delay = dict(
              type='int', required=False, default=1),
        )
    )
    try:
        _deal_with_jenkins(conf)
    except urllib2.HTTPError as e:
        conf.fail_json(msg="Jenkins failed.\n\n%s\n\n%s\n" % (e.msg, e.read()))


def _deal_with_jenkins(conf):
    headers={}
    task = conf.params['task']
    jenkins_url = conf.params['url']
    prepare_shutdown_url = jenkins_url + 'quietDown'
    restart_url = jenkins_url + 'restart'
    jobs_check_url = jenkins_url + 'computer/api/xml?xpath=//busyExecutors'
    username = conf.params['username']
    password = conf.params['password']
    shutdown_check_delay = conf.params['shutdown_check_delay']

    # first, detect if jenkins is running with security turned on or not
    # because we might be working with a brand new jenkins install that
    # has not had the security settings applied yet



    # ansible < 2.0 does not do basic auth properly, got to handle it here
    if username is not None and password is not None:
      headers["Authorization"] = "Basic %s" % base64.b64encode(
        "%s:%s" % (username, password))

    if task in ('install_plugin', 'restart'):
      # check if security is enabled or not
      try:
        res = open_url(jenkins_url)
        if res.getcode() == 200:
          del(headers["Authorization"])
      except:
        pass

    if task == 'install_plugin':
      install_timeout = float(conf.params['plugin_install_timeout'])
      install_retries = int(conf.params['plugin_install_retries'])
      plugin = conf.params['plugin']
      version = conf.params['version']
      plugin_request_headers = headers.copy()
      plugin_request_headers['Content-Type'] = 'text/xml'

      if version == 'latest':
        plugin_download_url = 'http://updates.jenkins-ci.org/latest/%s.hpi' % plugin
      else:
        plugin_download_url = 'http://updates.jenkins-ci.org/download/plugins/%s/%s/%s.hpi' % (plugin, version, plugin)

      plugin_path = '/var/lib/jenkins/plugins/%s.jpi' % plugin

      # always unpin the plugin, we want to control versions
      if os.path.exists(plugin_path + '.pinned'):
        os.unlink(plugin_path + '.pinned')

      current_version = _get_installed_plugin_version(plugin)

      if version == 'latest' or current_version != version:
        plugin_request = open_url(plugin_download_url)
        with open(plugin_path, 'wb') as pfp:
          pfp.write(plugin_request.fp.read())
          conf.exit_json(changed=True, result="Jenkins plugin %s uploaded" % plugin)

      conf.exit_json(changed=False, result="Jenkins plugin %s already installed" % plugin)

    if task == 'restart':
      try:
        # sometimes, jenkins is started up enough to do things, but
        # not started up enough to prepare to shutdown, which makes
        # the prepare shutdown url gives a 500. So, retry it after a delay
        open_url(prepare_shutdown_url, headers=headers, method='POST', timeout=120)
      except:
        time.sleep(60)
        open_url(prepare_shutdown_url, headers=headers, method='POST', timeout=120)
        # if it doesn't work after letting jenkins warm up after jenkins
        # appears to be working, then just fail.

      # Wait until there are no jobs running
      jobs_running = True
      while jobs_running:
        try:
          res = open_url(jobs_check_url, headers=headers)
          output = ''.join(res.readlines())
          jobs_running = '<busyExecutors>0</busyExecutors>' not in output
        except Exception as e:
          pass
        time.sleep(shutdown_check_delay)

      try:
        open_url(restart_url, headers=headers, method='POST')
      except:
        # Jenkins will immediately shutdown and restart. It also redirects
        # to the index page. That means there are many errors we might have
        # to handle here, socket errors, httplib errors, urllib2 errors etc.
        # so if we've got this far we can be reasonably confident that jenkins
        # is working, and any errors here are due to it not being available
        # during some stage of the restart. So, catch and ignore everything.
        # This will not be needed with ansible 2, because we can tell
        # open_url not to follow the redirect.
        pass
      finally:
        # Now we need to wait for jenkins to fully start up.
        task = 'wait_for_startup'

    if task == 'wait_for_startup':
      # any non-error response code is enough to let us know jenkins is running.
      response_code = 503
      while response_code > 499:
        try:
          # don't send the auth headers, a 403 is an expected response
          # and shows jenkins is running
          response_code = open_url(jenkins_url).getcode()
          time.sleep(1)
        except Exception as e:
          if hasattr(e, 'code'):
            response_code = e.code
          time.sleep(1)

      conf.exit_json(changed=True, result="Jenkins running")


# import site snippets
from ansible.module_utils.basic import *
from ansible.module_utils.urls import *
main()
