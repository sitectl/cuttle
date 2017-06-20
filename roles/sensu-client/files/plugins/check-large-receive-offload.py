#!/usr/bin/env python
#
# Checks that large receive offload is disabled
#
# Return CRITICAL if large receive offload is enabled
#
# Dean Daskalantonakis <ddaskal@us.ibm.com>

import argparse
import re
import subprocess
import sys

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2


def exit_with_error_status(warning):
    if warning:
        sys.exit(STATE_WARNING)
    else:
        sys.exit(STATE_CRITICAL)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--devices', help='primary interface devices',
                        required=True)
    parser.add_argument('-w', '--warning', action='store_true')
    args = parser.parse_args()

    crit_level = 'CRITICAL'
    if args.warning:
        crit_level = 'WARNING'

    for eth in [s.strip() for s in args.devices.split(',')]:
        cmd = "ethtool -k %s | grep large-receive-offload | \
               grep ' off'" % (eth)

        try:
            lro_check = subprocess.check_call(cmd, shell=True)
        except subprocess.CalledProcessError as e:
            print(e.output)
            print('%s: Device %s has large-receive-offload (LRO) enabled'
                  % (crit_level, eth))
            exit_with_error_status(args.warning)

        print('Device %s has large-receive-offload (LRO) disabled' % (eth))

    sys.exit(STATE_OK)

if __name__ == "__main__":
    main()
