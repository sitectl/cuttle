#!/usr/bin/python
import re
import socket
import subprocess
import time

def _get_key_value_pair(key, stanza):
    value = None
    for line in stanza:
        if key in line:
            parts = line.split(':')
            value = parts[1].strip()
    return value


def handle_k10temp(stanza):
    temp = _get_key_value_pair('temp1_input', stanza)
    return 'temp', temp


def handle_fam15h_power(stanza):
    power = _get_key_value_pair('power1_input', stanza)
    return 'power', power


def stanza_type_device(stanza):
    m = re.match(r'(\w+)-(pci-[0-9a-fA-F]+)', stanza[0])
    if not m:
        raise Exception("Unkown sensor type %s" % stanza[0])
    return m.group(1), m.group(2)


def output_graphite(sensor_type, device, value):
    hostname = socket.gethostname().split('.')
    shortname = hostname[0]
    datacenter = hostname[1]
    unixtime = int(time.time())
    print "stats.%s.%s.%s.%s %s %d" % (shortname, datacenter, sensor_type,
                                       device, value, unixtime)


def main():
    stanzas = []
    output = subprocess.check_output(['sensors -u'], shell=True)
    current_stanza = []
    for line in output.split('\n'):
        if len(line) == 0 and len(current_stanza):
            stanzas.append(current_stanza)
            current_stanza = []
        else:
            current_stanza.append(line)

    for stanza in stanzas:
        try:
            sensor, device = stanza_type_device(stanza)
            func = globals()['handle_%s' % sensor]
            sensor_type, value = func(stanza[1:])
            output_graphite(sensor_type, device, value)
        except:
            continue

if __name__ == '__main__':
    main()

