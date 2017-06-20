#!/usr/bin/env python
#
#  metrics-network-queues.py
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#  Python 2.7+ (untested on Python3, should work though)
#
# USAGE:
#
# metrics-network-queues.py -n <process_name> [-s <graphite_scheme>]
#
# DESCRIPTION:
# Finds the pid[s] corresponding to a process name and obtains the lengths of
# the receive and send network queues for all of the process' sockets. This
# data is gathered from the "netstat -tpane" command.
#
# Code adapted from Jaime Gogo's script in the Sensu Plugins community
# https://github.com/sensu-plugins/sensu-plugins-process-checks/blob/master/bin/metrics-per-process.py
#
# Released under the same terms as Sensu (the MIT license); see MITLICENSE
# for details.
#
# Siva Mullapudi <scmullap@us.ibm.com>

import argparse
import sys
import os
import time
import subprocess

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2

PROC_ROOT_DIR = '/proc/'

def find_pids_from_name(process_name):
    '''Find process PID from name using /proc/<pids>/comm'''

    pids_in_proc = [ pid for pid in os.listdir(PROC_ROOT_DIR) if pid.isdigit() ]
    pids = []
    for pid in pids_in_proc:
        path = PROC_ROOT_DIR + pid
        if 'comm' in os.listdir(path):
            file_handler = open(path + '/comm', 'r')
            if file_handler.read().rstrip() == process_name:
                pids.append(int(pid))
    return pids

def search_output(output, token):
    matches = ""
    for line in output.splitlines():
        if token in line:
            matches = matches + line + "\n"
    return matches.rstrip("\n")

def sum_dicts(dict1, dict2):
    return dict(dict1.items() + dict2.items() +
        [(k, dict1[k] + dict2[k]) for k in dict1.viewkeys() & dict2.viewkeys()])

def queue_lengths_per_pid(pid):
    '''Gets network rx/tx queue lengths for a specific pid'''

    process_queues = {'receive_queue_length': 0, 'send_queue_length': 0}
    netstat = subprocess.check_output(['netstat -tpane'], shell=True)
    process_sockets = search_output(netstat, str(pid))

    for socket in process_sockets.splitlines():
        rx_queue_length = int(socket.split()[1])
        tx_queue_length = int(socket.split()[2])
        process_queues['receive_queue_length'] += rx_queue_length
        process_queues['send_queue_length'] += tx_queue_length

    return process_queues

def multi_pid_queue_lengths(pids):
    stats = {'receive_queue_length': 0, 'send_queue_length': 0}
    for pid in pids:
        stats = sum_dicts(stats, queue_lengths_per_pid(pid))
    return stats

def graphite_printer(stats, graphite_scheme):
    now = time.time()
    for stat in stats:
        print "%s.%s %s %d" % (graphite_scheme, stat, stats[stat], now)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--process_name', required=True)
    parser.add_argument('-s', '--scheme', required=True)
    args = parser.parse_args()

    pids = find_pids_from_name(args.process_name)

    if not pids:
        print 'Cannot find pids for this process. Enter a valid process name.'
        sys.exit(STATE_CRITICAL)

    total_process_queues = multi_pid_queue_lengths(pids)
    graphite_printer(total_process_queues, args.scheme)

    sys.exit(STATE_OK)

if __name__ == "__main__":
    main()

