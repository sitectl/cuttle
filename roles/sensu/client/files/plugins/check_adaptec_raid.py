#!/usr/bin/env python

# Copyright 2016, Craig Tracey <craigtracey@gmail.com>
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations

import argparse
import os
import re
import subprocess
import sys

SUCCESS = 'success'
CRITICAL = 'critical'
WARNING = 'warning'

RETURN_STATUS = {
    SUCCESS: 0,
    CRITICAL: 2,
    WARNING: 1,
}
DEFAULT_FAILED_RETURN = CRITICAL
DEFAULT_ARCCONF_PATH = '/usr/Adaptec_Event_Monitor/arcconf'


def exit_with_status(status, criticality):
    return_status = None
    return_text = None
    if not status == CRITICAL:
        return_text = status
        return_status = RETURN_STATUS[status]
    else:
        return_text = criticality
        return_status = RETURN_STATUS[criticality]
    print("Check status: %s" % return_text)
    sys.exit(return_status)


def arcconf_exists(path):
    return os.path.exists(path)


def check_adaptec_status(args):
    if not arcconf_exists(args.arcconf_path):
        print("arcconf utility no present at %s" % args.arcconf_path)
        exit_with_status(WARNING, args.criticality)

    check_commands = (
        (['GETCONFIG', '1'],
         r"\s*Controller Status\s*:\s*(.*)",
         "Optimal", "Controller status not optimal"),
        (['GETCONFIG', '1', 'LD'],
         r"\s*Status of logical device\s*:\s*(.*)",
         "Optimal", "Logical drive(s) not optimal"),
        (['GETCONFIG', '1', 'PD'],
         r"\s*S.M.A.R.T. warnings\s*:\s*(.*)",
         "0", "Physical device SMART warnings", WARNING)
    )

    statuses = []
    for command in check_commands:
        status = _run_command(args, *command)
        statuses.append(status)

    if CRITICAL in statuses:
        exit_with_status(CRITICAL, args.criticality)
    elif WARNING in statuses:
        exit_with_status(WARNING, args.criticality)
    exit_with_status(SUCCESS, args.criticality)


def _run_command(args, command, regex, expected, hint, failed_status=CRITICAL):
    cmd = [args.arcconf_path]
    cmd += command

    output = subprocess.check_output(cmd)
    failed = False
    found = False
    for line in output.split('\n'):
        match = re.match(regex, line)
        if match:
            found = True
            status = match.groups(1)[0]
            if status.lower() != expected.lower():
                failed = True

    if not found:
        print("Failed to determine RAID status "
              "with command: '%s'" % " ".join(cmd))
        return WARNING
    if failed:
        print("Failed RAID check: %s" % hint)
        print("Failed command: '%s'" % " ".join(cmd))
        return failed_status
    return SUCCESS


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('-a', '--arcconf-path',
                        default=DEFAULT_ARCCONF_PATH,
                        help="override the default arcconf path")

    parser.add_argument('-c', '--controller',
                        default=1,
                        help="controller to check")

    parser.add_argument('-z', '--criticality',
                        default=DEFAULT_FAILED_RETURN,
                        choices=RETURN_STATUS.keys(),
                        help="override the criticality upon failure")

    args = parser.parse_args()
    try:
        check_adaptec_status(args)
    except Exception as e:
        print("Failed to check RAID status: %s" % e)
        exit_with_status(CRITICAL, args.criticality)
    exit_with_status(SUCCESS, args.criticality)


if __name__ == '__main__':
    main()
