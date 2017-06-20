#!/bin/bash

while getopts 'z:' OPT; do
  case $OPT in
    z)  CRITICALITY=$OPTARG;;
  esac
done

CRITICALITY=${CRITICALITY:-critical}

if $(which ifquery >/dev/null 2>&1); then  # for ubuntu
  for IFACE in $(ifquery --list); do
    for VIP in $(ifquery ${IFACE} | awk '/^ucarp-vip:/ {print $2}'); do
      if ! ps -ef | grep '/usr/sbin/ucarp' | grep ${VIP} >/dev/null; then
        echo "no ucarp process is running for IP ${VIP}"
        if [ "$CRITICALITY" == "warning" ]; then
          exit 1
        else
          exit 2
        fi
      fi
    done
  done
else # for centos/rhel
  for VIP in $(awk '/^[^#]*VIP_ADDRESS/' /etc/ucarp/*.conf | sed 's/.*VIP_ADDRESS="\([^,]*\)"/\1/g'); do
    if ! ps -ef | grep '/usr/sbin/ucarp' | grep ${VIP} >/dev/null; then
      echo "no ucarp process is running for IP ${VIP}"
      if [ "$CRITICALITY" == "warning" ]; then
        exit 1
      else
        exit 2
      fi
    fi
  done
fi

echo "All interfaces configured with uCARP have running process"
