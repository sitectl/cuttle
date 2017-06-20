#!/usr/bin/env python
#
#  metrics-process-usage.py
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#  Python 2.7+ (untested on Python3, should work though)
#  Python module: psutil https://pypi.python.org/pypi/psutil
#
# USAGE:
#
#  metrics-process-usage.py -n <process_name> -w <cpu_warning_pct> -c <cpu_critical_pct> -W <mem_warning_pct> -C <mem_critical_pct> [-s <graphite_scheme>] [-z <criticality>]
#
# DESCRIPTION:
# Finds the pid[s] corresponding to a process name and obtains the necessary
# cpu and memory usage stats. Returns WARNING or CRITICAL when these stats
# exceed user specified limits.
#
# Code adapted from Jaime Gogo's script in the Sensu Plugins community:
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
import psutil

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
CRITICALITY = 'critical'

PROC_ROOT_DIR = '/proc/'

def switch_on_criticality():
    if CRITICALITY == 'warning':
        sys.exit(STATE_WARNING)
    else:
        sys.exit(STATE_CRITICAL)

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

def sum_dicts(dict1, dict2):
    return dict(dict1.items() + dict2.items() +
        [(k, dict1[k] + dict2[k]) for k in dict1.viewkeys() & dict2.viewkeys()])

def stats_per_pid(pid):
    '''Gets process stats, cpu and memory usage in %, using the psutil module'''

    stats = {}
    process_handler = psutil.Process(pid)
    stats['cpu_percent'] = process_handler.cpu_percent(interval=0.1)
    stats['memory_percent'] = process_handler.memory_percent()

    return stats

def multi_pid_process_stats(pids):
    stats = {'cpu_percent': 0, 'memory_percent': 0}
    for pid in pids:
        stats = sum_dicts(stats, stats_per_pid(pid))
    return stats

def graphite_printer(stats, graphite_scheme):
    now = time.time()
    for stat in stats:
        print "%s.%s %s %d" % (graphite_scheme, stat, stats[stat], now)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--process_name', required=True)
    parser.add_argument('-w', '--cpu_warning_pct', required=True)
    parser.add_argument('-c', '--cpu_critical_pct', required=True)
    parser.add_argument('-W', '--memory_warning_pct', required=True)
    parser.add_argument('-C', '--memory_critical_pct', required=True)
    parser.add_argument('-s', '--scheme', required=True)
    parser.add_argument('-z', '--criticality', default='critical')
    args = parser.parse_args()

    CRITICALITY = args.criticality

    pids = find_pids_from_name(args.process_name)

    if not pids:
        print 'Cannot find pids for this process. Enter a valid process name.'
        switch_on_criticality()

    total_process_stats = multi_pid_process_stats(pids)
    graphite_printer(total_process_stats, args.scheme)

    if total_process_stats['cpu_percent'] > float(args.cpu_critical_pct) or \
       total_process_stats['memory_percent'] > float(args.memory_critical_pct):
       print 'CPU Usage and/or memory usage at critical levels!!!'
       switch_on_criticality()

    if total_process_stats['cpu_percent'] > float(args.cpu_warning_pct) or \
       total_process_stats['memory_percent'] > float(args.memory_warning_pct):
       print 'Warning: CPU Usage and/or memory usage exceeding normal levels!'
       sys.exit(STATE_WARNING)

    sys.exit(STATE_OK)

if __name__ == "__main__":
    main()

