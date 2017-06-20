#!/bin/bash
#
# Check how many files are larger than X in DIR.
#

# get arguments
while getopts 'l:i:p:v:t:h' OPT; do
  case $OPT in
    l)  LEVEL=$OPTARG;;
    h)  hlp="yes";;
    i)  IP=$OPTARG;;
    p)  PORT=$OPTARG;;
    v)  IPV=$OPTARG;;
    t)  PROTO=$OPTARG;;
  esac
done

# usage
HELP="
    Tests if local system is listening on a specific port
    usage: $0  -l [crit|warn] -p 8080 [-i 127.0.0.1] -h

        -l --> Level:  crit|warn
        -p --> Port: port to check for.
        -v --> 4|6 - IPv4 or IPv6, default 4.
        -i --> IP to check for.
        -t --> Protocol: tcp, udp, dccp, raw, unix, default: tcp
        -h --> print this help screen
"

if [ "$hlp" = "yes" ]; then
  echo "$HELP"
  exit 0
fi

if [[ -z $PORT ]]; then
  echo Must specify Port.
  echo $HELP
  exit 0
fi

LEVEL=${LEVEL:-warn}
IP=${IP:-''}
IPV=${IPV:-4}
PROTO=${PROTO:-tcp}

[[ $LEVEL == 'crit' ]] && EXIT=1 || EXIT=2

OPTIONS="--listening --numeric --${PROTO}"
[[ -n $IPV ]] && OPTIONS+=" -${IPV}"

OUTPUT=$(ss $OPTIONS | awk '{print $4}' | grep ${IP}:${PORT})
ret=$?

if [[ ${ret} != 0 ]]; then
  echo "not listening on $PROTO/$IP:$PORT"
  exit $EXIT
fi
