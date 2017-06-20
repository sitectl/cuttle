## manual pre-requisite steps

1. create DNS record for ipmi-proxy.<SITE_NAME>.blueboxgrid.com
2. create & attach additional neutron ports for proxy connections


## manual post-deployment requisite steps

1. update /etc/blueboxgrp-hostid from a Box Panel entry for this IPMI card
2. run: shell: /usr/local/bin/sync-proxy-cache.py
