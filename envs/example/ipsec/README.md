IPSEC Example Environment
-------------------------

Environment conists of 4 servers ... two IPSEC servers that create a point-to-point VPN over eth1.  Each server has a second network on eth2.  There are two regular servers with no ansible roles `test1` and `test2`.  These are on the second networks of each of the IPSEC servers.

If using StrongSwan, both the package and service name will be `strongswan` (default in the environment). If using OpenSwan, the ipsec.implementation.package will be `openswan` and the ipsec.implementation.service will be `ispec` (look in the comments below for configuration).

Bring up the environment:

```
$ ursula --vagrant envs/example/ipsec site.yml
```

Set up static routes on the test servers:

```
$ vagrant ssh test1 -c "sudo ip route add 172.16.20.0/24 via 172.16.10.100"
$ vagrant ssh test2 -c "sudo ip route add 172.16.10.0/24 via 172.16.20.100"
```

Run tcpdump on one of the ipsec servers and leave it running:

```
$ vagrant ssh ipsec-server -c 'sudo tcpdump -n -i eth1 esp or udp port 500 or udp port 4500'
```

and then try to ping from one test server to the other from another terminal window:

```
$ vagrant ssh test2 -c 'ping 172.16.10.200'   
PING 172.16.10.200 (172.16.10.200) 56(84) bytes of data.
64 bytes from 172.16.10.200: icmp_seq=1 ttl=62 time=0.933 ms
64 bytes from 172.16.10.200: icmp_seq=2 ttl=62 time=1.06 ms
```

In the tcpdump session you should see the following:

```
21:42:57.120282 IP 172.16.0.101.4500 > 172.16.0.100.4500: UDP-encap: ESP(spi=0xf7893654,seq=0x8), length 132
21:42:57.120680 IP 172.16.0.100.4500 > 172.16.0.101.4500: UDP-encap: ESP(spi=0xda5b24b4,seq=0x8), length 132
21:42:58.124660 IP 172.16.0.101.4500 > 172.16.0.100.4500: UDP-encap: ESP(spi=0xf7893654,seq=0x9), length 132
```

woot!  this means the VPN is working.



<!-- --- ipsec-client.yml with openswan
ipsec:
  nat_enabled: True
  config:
    nat_traversal: "yes"
    virtual_private: "%v4:{{ hostvars['ipsec-client'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-client'][private_interface]['ipv4']['netmask'] }}"
    protostack: "netkey"
  connections:
    example:
      authby: "secret"
      forceencaps: "yes"
      auto: "start"
      rekey: "yes"
      ikelifetime: "8h"
      salifetime: "1h"
      ike: "aes256-sha1-modp1536!"
      esp: "aes256-sha1!"
      dpddelay: 30
      dpdtimeout: 120
      dpdaction: "restart"
      left: "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      leftid: "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      leftsourceip: "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      leftsubnet: "{{ hostvars['ipsec-client'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-client'][private_interface]['ipv4']['netmask'] }}"
      right: "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      rightid: "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      rightsubnet: "{{ hostvars['ipsec-server'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-server'][private_interface]['ipv4']['netmask'] }}"
  sharedkeys:
    example:
      remote_ip:  "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      key: "dfgffk4ltjk3jkl234t234t"

  nat_rules: |
    -A FORWARD --in-interface {{ private_device_interface }} -j ACCEPT
    COMMIT
    # NAT RULES
    *nat
    :PREROUTING ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    -F
    -A POSTROUTING -o {{ public_device_interface }} ! -d {{ hostvars['ipsec-server'][private_interface]['ipv4']['network'] }} --j MASQUERADE
 -->
 
 <!-- --- ipsec-server.yml with openswan
ipsec:
  config:
    nat_traversal: "yes"
    virtual_private: "%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!{{ hostvars['ipsec-client'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-client'][private_interface]['ipv4']['netmask'] }}"
    protostack: "netkey"
  connections:
    example:
      authby: "secret"
      forceencaps: "yes"
      auto: "start"
      ike: "aes256-sha1-modp1536!"
      ikelifetime: 86400s
      dpddelay: 30
      dpdtimeout: 120
      dpdaction: restart
      esp: "aes256-sha1!"
      keylife: 3600s
      rekeymargin: 540s
      compress: "no"
      keyingtries: "%forever"
      left: "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      leftid: "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      leftsourceip: "{{ hostvars['ipsec-server'][public_interface]['ipv4']['address'] }}"
      leftsubnet: "{{ hostvars['ipsec-server'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-server'][private_interface]['ipv4']['netmask'] }}"
      right: "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      rightid: "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      rightsubnet: "{{ hostvars['ipsec-client'][private_interface]['ipv4']['network'] }}/{{ hostvars['ipsec-client'][private_interface]['ipv4']['netmask'] }}"
  sharedkeys:
    example:
      remote_ip:  "{{ hostvars['ipsec-client'][public_interface]['ipv4']['address'] }}"
      key: "dfgffk4ltjk3jkl234t234t" -->
