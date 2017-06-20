#!/usr/bin/env python

# Copyright 2016 Blue Box, an IBM Company
# Copyright 2016 Paul Durivage <pmduriva at us.ibm.com>
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


from __future__ import print_function

import argparse
import os
import sys
import datetime

# Standard Nagios return codes
OK       = 0
WARNING  = 1
CRITICAL = 2
UNKNOWN  = 3

# time deltas to indicate whether last backup time is warning or critical
WARNING_TIME = datetime.timedelta(days=1)
CRITICAL_TIME = datetime.timedelta(days=3)

LOG_PATH = '/backup/percona/percona-backup.last.log'

argparser = argparse.ArgumentParser()
argparser.add_argument('--criticality', help='Set sensu alert level, default is critical',
                       default='critical')
options = argparser.parse_args()

def switch_on_criticality():
    if options.criticality == 'warning':
        sys.exit(WARNING)
    else:
        sys.exit(CRITICAL)

def main():
    if not os.path.isfile(LOG_PATH):
        print('Log file missing: %s' % LOG_PATH, file=sys.stderr)
        sys.exit(UNKNOWN)

    with open(LOG_PATH) as f:
        data = f.readline()

    try:
        exit_code, timestamp = data.split()
    except ValueError:
        print('Unable to get exit code or timestamp from log', file=sys.stderr)
        sys.exit(UNKNOWN)

    if int(exit_code) != 0:
        print('Critical: Last backup exited with status: %s' % exit_code,
              file=sys.stderr)
        switch_on_criticality()

    try:
        parsed = datetime.datetime.fromtimestamp(float(timestamp))
    except ValueError:
        print("Couldn't parse date from log file", file=sys.stderr)
        sys.exit(UNKNOWN)

    now = datetime.datetime.now()
    if now - parsed > CRITICAL_TIME:
        print('Critical: Last backup greater than 72 hours ago',
              file=sys.stderr)
        switch_on_criticality()
    elif now - parsed > WARNING_TIME:
        print('Warning: Last backup greater than 24 hours ago',
              file=sys.stderr)
        sys.exit(WARNING)
    else:
        sys.exit(OK)


if __name__ == '__main__':
    main()
