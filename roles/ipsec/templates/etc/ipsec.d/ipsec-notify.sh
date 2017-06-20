#!/bin/sh

echo $PLUTO_VERB

case "$PLUTO_VERB:$1" in
    up-client:)
        ip link add {{ ipsec.vti_interface }} type vti key 100 remote {{ ipsec.connections.example.right }} local {{ ipsec.connections.example.left }}
        ip link set {{ ipsec.vti_interface }} up
        ip addr add {{ ipsec.connections.example.left_vti_ip }} remote {{ ipsec.connections.example.right_vti_ip }} dev {{ ipsec.vti_interface }}
        ;;
    down-client:)
        ip tunnel del {{ ipsec.vti_interface }}
        ;;
esac
