#!/usr/bin/env bash
#
# Send 2 ARP REQUEST broadcast packets and alert if:
#   1. There are no replies.
#   2. There is more than 1 MAC address in the replies.

while getopts 'I:d:z:' OPT; do
  case "$OPT" in
    I) interface="$OPTARG";;
    d) destination="$OPTARG";;
    z) CRITICALITY="$OPTARG";;
  esac
done

CRITICALITY=${CRITICALITY:-critical}

if [[ -z "$interface" || -z "$destination" ]]; then
  echo "Usage: $0 -I device -d destination"
  exit 1
fi

output=$(arping -b -c 2 -I $interface $destination)

if [ $? -ne 0 ]; then
  echo "ERROR: No ARP replies for destination: $destination"
  echo "$output"
  if [ "$CRITICALITY" == "warning" ]; then
    exit 1
  else
    exit 2
  fi
fi

mac_address=$(echo "$output" | grep 'reply from' | awk '{ print $5 }' | sort | uniq)
if [[ -z "$mac_address" ]]; then
  echo "WARN: Error parsing output for MAC addresses:"
  echo "$output"
  exit 1
fi

num_address=$(echo "$mac_address" | wc -l)
status="Received replies from ${mac_address//$'\n'/,} for destination: $destination"

if [ $num_address -ne 1 ]; then
  echo "ERROR: $status"
  echo "$output"
  if [ "$CRITICALITY" == "warning" ]; then
    exit 1
  else
    exit 2
  fi
else
  echo "OK: $status"
  exit 0
fi
