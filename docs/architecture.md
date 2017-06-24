Overall Architecture
====================

Blue Box primarily uses Cuttle as a way to manage Openstack Clouds across 30+
datacenters. Many of those datacenters are in locations with minimal (if any)
internet access and therefore each DataCenter has all of the infrastructure
(logging, monitoring, etc) required for daily operations local to the datacenter
with minimal connectivity.  Each DataCenter does have a IPSEC (hardware and/or
Vyatta managed outside of this repo, although it can be simulated using the
ipsec role) tether back to a central location which hosts mirrors, flapjack,
 bastion, and monitoring/logging for the remote Cuttle systems.

Blue Box refers to Cuttle installed in this manner as Site Controller.  The
Central system is imaginatively referred to as "Central Site Controller" and
each datacenter that connects through to it as "Remote Site Controller".

Central Site Controller
-----------------------

### Access
Authorized users can SSH to the Central Site Controller Bastion. Following this,
any Remote SiteController, or any Openstack Deployment based on any Remote Site
Controller can be accessed via SSH from the Central Bastion as long as the
user is in the correct group for that server.

#### Control Portal
An Apache web portal, `control.XXXX.com` is being hosted by the
Central Controller to allow authorized users to monitor all deployments beneath
it. The portal can be accessed though the multi-factor authentication of
boxpanel. Once logged into the portal, sites for each Remote Site Controller can
be reached without further authentication, using OpenID.

### Included
The Central Site Controller has:
  * [Bastion](#bastion)
  * [IPMI Proxy](#ipmi-proxy)
  * [OpenID Proxy](#openid-proxy)
  * [Monitoring](#monitoring)
  * [Mirror & Squid Proxy](#mirror--squid-proxy)


#### Bastion
It houses:
  * Support Tools (git_pull cronjobs, update info)
  * SSHAuthMux (shared ssh authentication)
  * ttyspy (sends all input/output to a remote server over TLS)

The Bastion is merely a secure location post-connection. It also maintains the
state of the Central Site Controller to ensure it is always up-to-date.

#### IPMI Proxy
Allows connection to IPMI of servers. This enables the Central Site Controller
to control the remote Site Controllers, even if powered off.

#### OpenID Proxy
Allows connection to OpenID of servers. This enables the Central Control Pod to
use OpenID, maintaining a single identity with a given set of authentication.

#### Monitoring
It houses:
  * Sensu (system monitoring framework)
  * RabbitMQ (AMQP - advanced message queuing protocol)
  * Flapjack (alert-routing, event processing)

Ensures that the Central Controller and everything directly controlled by it is
running properly with chronological checks. Checks are done via the Sensu client
within the Central Site Controller, and their results are passed (using
RabbitMQ) to the Sensu server, which are passed the the Sensu Redis server.
Redis servers allow the checks to be key-mapped, which allows higher
availability (retaining more events without loss).

Apart from self-checking, the Central Site Controller also monitors all Remote
Site Controller deployments beneath it. All checks done by Remote Site
Controllers are passed to the Central Site Controller Sensu host.

Pagerduty, an incident resolution service, is also enabled. Alerts from the
Sensu host within the Central Site Controller are passed to a Redis server.
Flapjack retrieves data from the Redis server, then from there, alerts are
passed to Pagerduty.

The Uchiwa dashboard allows users to view Sensu checks by calling the
Sensu API which calls the Sensu Redis server.

To gain a better understanding of how the overall monitoring works, view the
[Monitoring Diagram](#monitoring-diagram)

#### Mirror & Squid Proxy
It houses _four_ mirrors:
  * Apt
  * PyPi
  * Gem
  * File

A detailed listing of mirror contents can be found in your ansible inventory
The mirror is used by all Site Controller and OpenStack hosts and is accessed
via each Site Controller's Squid proxy (installed on the Bootstrapper).

The Central Site Controller also houses a [Squid caching proxy](http://www.squid-cache.org/)
that is used to proxy domains such as [github.com](github.com). The proxy can be used as an
upstream/parent proxy for each Remote Site Controller's Squid.

Remote Site Controller
----------------------

### Deploying
To deploy a Remote Site Controller, a working environment is required.
The [Site Controller Generator](#site-controller-generator) creates this for the
user.
To further understand how to deploy, read the docs:
  * write docs

### Access
From the Bastion of the Central Site Controller, authorized users can access the
remote Site Controllers deployed via SSH through an IPSec tunnel connected to
each VPN. To keep remote site security and hardware managable, reverse proxying
is used. Reverse proxy servers act as a gateway between the Central Site
Controller and each Remote Site Controller. A virtual router, known as a Vyatta
handles this proxy service, by executing DNS lookups, then rerouting original
request. In other words, rather than accessing the remote site directly from the
Central, the Central Site Controller sends a request to access the remote site
via the Vyatta, which then finds the correct private address of the Remote Site
Controller so it may send the request from the Central to it.

### Included
Each Remote Site Controller has:
  * [Bootstrapper](#bootstrapper)
  * [ELK](#elk)
  * [Monitoring](#monitoring-1)

#### Bootstrapper
The Bootstrapper host plays a vital role in the deployment and upgrade of Site
Controller and OpenStack hosts. The Bootstrapper is the first host installed
and converged in a deployment. For a local environment the Bootstrapper is the
only host that gets Ubuntu installed manually (not via pxe). The
Bootstrapper serves two primary functions:
  * Squid
  * PXE (Local deployments only)

It is important to note that no mirror roles are run on the Bootstrapper. For more
detailed information on the Bootstrapper's role in deployments, please read the
aforementioned deployment guides.

###### Squid
The Bootstrapper serves as a [Squid caching proxy](http://www.squid-cache.org/)
for Site Controller and OpenStack hosts. This is especially useful when installing
and upgrading packages. Some important commands involving Squid:
```
# check squid status
$ service squid3 status

# view access log
$ view /var/log/squid3/access.log

# view cache log
$ view /var/log/squid3/cache.log
```

###### PXE
For local deployments the Bootstrapper acts as a PXE server. This allows the
Site Controller team to install Ubuntu on SC and OpenStack hosts in an automated
fashion. The PXE files that are installed on the Bootstrapper are specified in the
environment's `group_vars/bootstrap.yml` and can be found on the server in
`/data/pxe/tftpboot`.
PXE files are installed when the Bootstrapper is converged, however, you must
specify `-e 'pxe_files=true'`, as the default is to skip file
installation. There is also a [playbook](https://github.com/IBM/cuttle/blob/master/playbooks/pxe-config.yml)
that only does PXE file installation. We have a practice of removing PXE files after deployment so
no host is accidentally wiped.

#### ELK
It houses:
  * Elasticsearch
  * Logstash
  * Kibana
  * OpenID Proxy

The ELK (Elasticsearch, Logstash, and Kibana) host manages logging. The logging
flow is very similar to that of monitoring. The Logstash Forwarder on an
Openstack Deployment or within the Remote Site Controller itself ships
designated logs to Logstash. Logstash then stores it in Elasticsearch, a search
engine that evaluates the collective of logs stored. The Kibana service allows
the user to search and create visualizations, all through the use of a web user
interface by pulling data from Elasticsearch.

To gain a better understanding of how the logging flow works, view the
[Logging Diagram](#logging-diagram)

#### Monitoring
It houses:
  * Sensu
  * RabbitMQ
  * IPMI Proxy
  * Grafana (with Graphite)

The automated Sensu checks done within Remote Site Controller notify the Sensu
host from the Central Site Controller, as stated.
A Remote Site Controller mimics the Central Site Controller by also monitoring
all deployments beneath it, which for a Remote Site Controller are Openstack
Deployments. Checks done by the Sensu client on each associated Openstack
Deployment are passed to the Remote Site Controller Sensu host.

Graphite, a monitoring tool that stores and passes data to Sensu, is implemented
into Grafana, a graph and dashboard builder for visualizing the time-series
metrics passed.

The two major components of Graphite used for monitoring are:
  * Carbon, a Twisted daemon that listens for time-series data,
  * Whisper, a simple database library for storing time-series data, and the

Monitoring Diagram
------------------
```
┌────── Central ────────┐      ┌────── Remote ────────┐   ┌──── Openstack ─────┐
│                       │      │                      │   │     Deployment     │
│      Auth Proxy  ────────────────> Apache           │   │                    │
│        │              │      │       │              │   │    Sensu Client    │
│        V              │      │       │              │   │         │          │
│ ┌─── Apache           │      │       │              │   │         │          │
│ │      │              │      │       │              │   └──────── │ ─────────┘
│ │      V              │      │       V              │             │
│ │    Uchiwa           │      │     Uchiwa           │             │
│ │      │              │      │       │              │             │
│ │      V              │      │       V              │             │
│ │    Sensu API        │      │     Sensu API        │             │
│ │      │              │      │       │              │             │
│ │      V              │      │       V              │             │
│ │    Sensu            │      │     Sensu            │             │
│ │    Redis Server     │      │     Redis Server     │             │
│ │      ^              │      │       ^              │             │
│ │      │              │      │       │              │             │
│ │    Sensu Server <──────┐   │     Sensu Server <─────────────────┘
│ │      ^              │  │   │              │       │
│ │      │              │  │   │              │       │
│ │      │              │  │   │              └─────────────┐
│ │    (RabbitMQ)       │  └─(RabbitMQ)───┐           │     │
│ │      │              │      │          │           │     │
│ │      │              │      │     Sensu Client     │     │
│ │    Sensu Client     │      │                      │     │
│ │                     │      └──────────────────────┘     │
│ │                     │                                   │
│ │    HTTP Broker  <─────────(Flapjack HTTP Handler)───────┘
│ │      │              │
│ │      V              │
│ │    Flapjack         │
│ │    Redis Server     │
│ │      ^              │
│ │      │              │
│ └──> Flapjack         │
│        │              │
└─────── │ ─────────────┘
         │
         V
       PagerDuty (not hosted)
```
A more detailed, graphical image can be found [here](https://github.com/IBM/cuttle/blob/master/docs/monitoring.png).


Logging Diagram
---------------
```
┌── Central ────┐   ┌─────── Remote ────────┐   ┌───── Openstack ──────┐
│               │   │                       │   │      Deployment      │
│  Auth Proxy ─────────> Apache             │   │                      │
│  (Apache)     │   │      │                │   │   Log Occurs         │
│               │   │      V                │   │       │              │
└───────────────┘   │    Kibana             │   │       V              │
                    │      │                │   │   Logstash Forwarder │
                    │      V                │   │   (Shipper)          │
                    │    Elasticsearch      │   │       │              │
                    │      ^                │   │       │              │
                    │      │                │   │       │              │
                    │    Logstash  <────────────────────┘              │
                    │      ^                │   └──────────────────────┘
                    │      │                │
                    │    Logstash Forwarder │
                    │    (Shipper)          │
                    │      ^                │
                    │      │                │
                    │    Log Occurs         │
                    └───────────────────────┘
```
A more detailed, graphical image can be found [here](https://github.com/IBM/cuttle/blob/master/docs/logging.png).

Site Controller Generator
-------------------------

[Site Controller Generator](https://github.com/IBM/cuttle-generator)

### Function

This tool generates working production environments based on a single input file
which contains variables specific to a desired site controller deployment. The
generated environment creates configurations, as well as documentation of what
configurations are established.


Future Development & Operations
-------------------------------

  * [Issue Triaging](#issue-triaging)


#### Issue Triaging
Whether issues are found by users or admins, there should be a portal accessible
and integrated into the control portal (limited access for users=reporters, full
access for admins = resolvers & reporters) where issues can be labeled with any
combination of:
  Priority:
    * _critical_,
    * _moderate_, or
    * _low_
  Status:
    * _unresolved_,
    * _in-progress_, or
    * _resolved_
