#!/bin/bash

while getopts 'z' OPT; do
  case $OPT in
    z)  CRITICALITY=$OPTARG;;
  esac
done

CRITICALITY=${CRITICALITY:-critical}

if lspci | grep RAID | grep -i 3ware >> /dev/null; then
    sudo check_3ware_raid.py -b /usr/sbin/tw-cli -z $CRITICALITY
elif lspci | grep RAID | grep -i "MegaRAID" >> /dev/null; then
    if [[ -e /etc/sensu/plugins/check-storcli.pl && -e /opt/MegaRAID/storcli/storcli64 ]];then
      sudo check-storcli.pl -p /opt/MegaRAID/storcli/storcli64 -Io 63 -z $CRITICALITY
    else
      sudo check_megaraid_sas.pl -b /usr/sbin/megacli -o 63 -z $CRITICALITY
    fi
elif lspci | grep RAID | grep -i "Adaptec" >> /dev/null; then
    sudo check_adaptec_raid.py -z $CRITICALITY
fi;
