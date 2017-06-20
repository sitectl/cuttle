# Deploying a Site Controller

## Table of Contents

* [Get Hosts](#order-hosts)
* [Prepare template-vars.yml & ansible-inventory](#prepare-template-varsyml-and-ansible-inventory)
* [Prepare Bastion](#prepare-bastion)
* [Special Considerations for CDL](#special-considerations-for-cdl)
* [Run CIMC validation](#run-cimc-validation-local-and-cisco-bom-only)
* [Converge Bootstrapper](#converge-bootstrapper)
* [PXE SC nodes (Local ONLY)](#pxe-sc-nodes-local-only)
* [Ensure SC nodes came up after PXE boot (Local ONLY)](#ensure-sc-nodes-came-up-after-pxe-boot-local-only)
* [Bootstrap other SC nodes (Local ONLY)](#bootstrap-other-sc-nodes-local-only)
* [Converge Site Controller](#converge-site-controller)
* [Converge Control (Dedicated and Local)](#converge-control-dedicated-and-local)
* [Run Flotsam](#run-flotsam)
* [PXE OpenStack nodes (Local ONLY)](#pxe-openstack-nodes-local-only)
* [Ensure OpenStack nodes came up after PXE boot (Local ONLY)](#ensure-openstack-nodes-came-up-after-pxe-boot-local-only)
* [Remove PXE files from Bootstrapper (Local ONLY)](#remove-pxe-files-from-bootstrapper-local-only)
* [Validate deployment](#validate-deployment)
* [Troubleshooting](#troubleshooting)
* [Legacy PureApp: Bootstrap VPN Node from Localhost](#legacy-pureapp-bootstrap-vpn-node-from-localhost)

## Get Hosts

Somehow you need to get a bunch of servers.  do that.

## Prepare template-vars.yml and ansible-inventory

Create environment and variables in ansible-inventory repo using [Site Controller Generator](https://github.com/IBM/cuttle-generator).

Update the following in `central.yml`:
  1. sensu.dashboard.datacenters
  2. grafana.remote_graphite.datasources
  3. openid_proxy.remote_locations  

## 1 to N Site Controller (Local ONLY)

Special considerations need to be made for a Local Site Controller that is used to support >1 OpenStack, as
sc-gen was written to support a 1:1 relationship between SC and OpenStack. After running sc-gen with the workbook,
three items need to be added to the respective environment:
  1. `pxe.servers`
  2. `pxe.dhcp_ranges`
  3. Static route in `host_vars/bootstrap01.yml`. The static route can be added manually on the machine but needs to be reflected in the env. The subnet is for the PXE network. For example: `ip route add 10.10.36.128/27 via 10.10.0.129 dev bond0`.

## Bootstrap nodes

Local (bootstrap01 ONLY):
```
cd ../ursula-flotsam

# trust host (you may need to change user)
ursula ../ansible-inventory/remote-$DC playbooks.keyprime.yml --limit bootstrap01

ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=admin' --ask-pass --ask-sudo-pass --sudo --limit bootstrap01
```

Central & Dedicated:
```
cd ../ursula-flotsam

# trust hosts
ursula ../ansible-inventory/remote-$DC playbooks.keyprime.yml

ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=root' --ask-pass --limit bootstrap01 -e '{"ansible_ssh_user": "root", "env_vars": {"http_proxy": "", "https_proxy": "", "no_proxy": "", "PERL_LWP_ENV_PROXY": 1}}'
ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=root' --ask-pass --limit monitor01 -e '{"ansible_ssh_user": "root", "env_vars": {"http_proxy": "", "https_proxy": "", "no_proxy": "", "PERL_LWP_ENV_PROXY": 1}}'
ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=root' --ask-pass --limit elk01 -e '{"ansible_ssh_user": "root", "env_vars": {"http_proxy": "", "https_proxy": "", "no_proxy": "", "PERL_LWP_ENV_PROXY": 1}}'
ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=root' --ask-pass --limit elk02 -e '{"ansible_ssh_user": "root", "env_vars": {"http_proxy": "", "https_proxy": "", "no_proxy": "", "PERL_LWP_ENV_PROXY": 1}}'
```

## Converge Bootstrapper / Bastion

Local:
```
ursula ../ansible-inventory/remote-$DC site.yml --limit bootstrap* -e 'pxe_files=true'
```

Dedicated:
```
ursula ../ansible-inventory/remote-$DC site.yml --limit bootstrap* -e '{"env_vars": {"http_proxy": "", "https_proxy": "", "no_proxy": "", "PERL_LWP_ENV_PROXY": 1}}'
```

Central:
```
ursula ../ansible-inventory/control-$DC site.yml --limit=bastion -e "@../ansible-inventory/bastion-users.yml" --ask-vault-pass --ask-su-pass
```

## PXE SC nodes (Local ONLY)

```
export IPMISUBNET=10.11.9
export IPMISTART=12
export IPMIEND=14
export IPMIUSER=admin
export IPMIPASS=admin

for ip in {$IPMISTART..$IPMIEND}; do
   echo $IPMISUBNET.$ip
   ipmitool -I lanplus -U $IPMIUSER -P $IPMIPASS -e - -H $IPMISUBNET.$ip chassis bootdev pxe
   ipmitool -I lanplus -U $IPMIUSER -P $IPMIPASS -e - -H $IPMISUBNET.$ip chassis power reset
   echo
done
```

If you're having trouble with pxe, run the following command on the bootstrap host to monitor dhcp traffic:
```
tcpdump -i bond0 -vvv -s 1500 '((port 67 or port 68) and (udp[8:1] = 0x1))'
```

## Ensure SC nodes came up after PXE boot (Local ONLY)

```
for i in {12..14}; do echo -n "10.11.10.$i "; ping -c 1 10.11.10.$i > /dev/null && echo OK || echo NOT DONE; done
```

## Bootstrap other SC nodes (Local ONLY)

```
cd ../ursula-flotsam

# trust hosts (you may need to change user)
ursula ../ansible-inventory/remote-$DC playbooks.keyprime.yml

ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=admin' --ask-pass --limit monitor01
ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=admin' --ask-pass --limit elk01
ursula ../ansible-inventory/remote-$DC playbooks/bootstrap.yml -e 'ansible_ssh_user=admin' --ask-pass --limit elk02
```

## Converge Site Controller

```
cd ../sitecontroller
ursula ../ansible-inventory/remote-$DC site.yml
```

## Converge Control (Dedicated and Local)

```
cd ../sitecontroller
ursula ../ansible-inventory/control-iad01 site.yml --limit tools --tags uchiwa,openid-proxy
```

## PXE OpenStack nodes (Local ONLY)

```
export IPMISUBNET=10.11.9
export IPMISTART=12
export IPMIEND=14
export IPMIUSER=admin
export IPMIPASS=admin

for ip in {$IPMISTART..$IPMIEND}; do
   echo $IPMISUBNET.$ip
   ipmitool -I lanplus -U $IPMIUSER -P $IPMIPASS -e - -H $IPMISUBNET.$ip chassis bootdev pxe
   ipmitool -I lanplus -U $IPMIUSER -P $IPMIPASS -e - -H $IPMISUBNET.$ip chassis power reset
   echo
done
```

## Ensure OpenStack nodes came up after PXE boot (Local ONLY)

```
export IPMISUBNET=10.11.9
export IPMISTART=12
export IPMIEND=14
export IPMIUSER=admin
export IPMIPASS=admin

for ip in {$IPMISTART..$IPMIEND}; do
   echo $IPMISUBNET.$ip
   ping -c 1 $IPMISUBNET.$ip > /dev/null && echo OK || echo NOT DONE
   echo
done
```

## Remove PXE files from Bootstrapper (Local ONLY)

```
ursula ../ansible-inventory/remote-$DC playbooks/pxe-config.yml -e 'pxe_files=false'
```

## Validate deployment

See [Validating a Remote Site Controller](https://github.com/IBM/cuttle/blob/master/docs/post_deploy_validation.md).

## Troubleshooting

Lost connection? You'll likely have problems with ssh agent forwarding.
```
fixssh
ssh-add -l
```
