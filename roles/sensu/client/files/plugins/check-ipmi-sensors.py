#!/usr/bin/env python
#
# Check whether there's warning and error in IPMI sensor status
#
# Return CRITICAL or WARNING when there's sensor error or there's PFA alert
#
# Fan He <fanhe@cn.ibm.com>

import argparse
import re
import subprocess
import sys

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2

def exit_error(criticality):
    if criticality == 'warning':
        sys.exit(STATE_WARNING)
    else:
        sys.exit(STATE_CRITICAL)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--debug', help='Enable ipmitool output debugging', action='store_true')
    parser.add_argument('--criticality', help='Set sensu alert level, "warning" or "critical" (default)', default='critical')
    args = parser.parse_args()

    # Check Sensor Data Record (SDR) Repository info by elist containing asserted discrete states
    cmd = "ipmitool sdr elist"
    try:
        elist = subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        print(e.output)
        exit_error(args.criticality)

    lines = elist.splitlines()
    error_messages = []

    for s in lines:
        if s == '':
            continue
        if args.debug:
            print(s)

        sensor = [x.strip() for x in s.split('|')]
        name = sensor[0]
        status = sensor[2]
        asserted_states = sensor[-1]

        # Check if there are sensor not in OK or No Status
        if status not in ['ok', 'ns']:
            error_messages.append("Sensor [%s] has unexpected status [%s] %s" % (name, status, asserted_states))

        # Additionally, check unexpecetd asserted states to discover PFA alerts for RAM and disks
        if re.match('DIMM\s\d+\Z', name) or re.match('Drive\s\d+\Z', name):
            if asserted_states == '':
                continue
            for state in [x.strip() for x in asserted_states.split(',')]:
                if state not in ['Drive Present', 'No Reading', 'Presence Detected']:
                    error_messages.append("Sensor [%s] has unexpected assertion [%s]" % (name, state))

    if len(error_messages) > 0:
        for msg in error_messages:
            print(msg)
        exit_error(args.criticality)

    sys.exit(STATE_OK)

if __name__ == "__main__":
    main()
