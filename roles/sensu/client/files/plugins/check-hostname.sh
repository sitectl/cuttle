#!/usr/bin/env bash

trap "{ echo 'unable to check hostname'; exit 2; }" ERR

while getopts 'k:v:' OPT; do
  case "$OPT" in
    k) key="$OPTARG";;  # e.g. ansible_nodename
    v) value="$OPTARG";;  # e.g. vagrant
  esac
done

[ -n "$value" ] || exit 0

host="$(hostname)"

if [ $(hostname) != "$value" ]; then
  if [ -n "$key" ]; then
    echo "hostname ($host) should match $key ($value)"
  else
    echo "hostname ($host) should be set to $value"
  fi
  exit 2
else
  exit 0
fi
