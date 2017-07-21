# How we manage Ansible Inventory with Cuttle

At BlueBox we try to move beyond "Infrastructure as Code" and instead aim for
"Infrastructure as Config". We firmly believe that the power of Configuration
Management tools like Ansible is in democratizing the install and Configuration
of infrastructure and software so that the Operator can focus on their core
competencies of running production systems.

To accomplish this we try and ensure that our systems (in this case Cuttle) can
be built and deployed by modifying configs, not code.  We try and anticipate
any changes an Operator might want to make and ensure that they can be modified
simply by updating the config (in this case we consider the Ansible Inventory
to be the config).  An Operator should not need to write or change Ansible tasks
to make changes to their environments such as:

* use a different apt repo for a package
* add hosts to DNS
* Add another Elasticsearch host to the cluster
* Modify Firewall rules

We also recognise that while we have hundreds (if not thousands) of configurable
options (ansible variables) in Cuttle the majority of the settings will be the
same across like environments, and thus should be set in a common area.

To accomplish this we host our Ansible inventories for similar environments in a
shared git repository (with any secrets encrypted with ansible vault). Our
git repository looks something like this (for a full example of this see
`envs/example` in this git repository):

```
├── defaults.yml
├── bastion
│   ├── group_vars
│   │   └── all.yml
│   ├── hosts
│   ├── ssh_config
│   └── secrets.yml
├── elk
│   ├── group_vars
│   │   └── all.yml
│   ├── heat_stack.yml
│   ├── hosts
│   │   └── server01.yml
│   ├── ssh_config
│   └── secrets.yml
├── monitor
│   ├── group_vars
│   │   └── all.yml
│   ├── hosts
│   ├── ssh_config
│   └── secrets.yml
```

For the most part our inventory looks much like a regular inventory, however we
do a few things differently:

## 1. ssh_config

We almost always include a `ssh_config` file for each environment which contains everything
needed to ssh into a host in that environment including settings things like hostname,
user, agent forwarding, proxycommand, etc. Our Ansible wrapper
[ursula-cli](https://github.com/blueboxgroup/ursula-cli) checks for the existence
of this ssh_config file in the inventory and passes it to Ansible to use.

It also means that any Operator can easily SSH to any server from the Bastion
server (as we keep our ansible inventory git repositories cloned on the Bastion)
and can simply run `ssh -F inventory/bacon/ssh_config elk01` to SSH into
the elk server for the `bacon` environment.

_note: ursula-cli will also attempt to create that ssh_config file for you if you
use it's built in vagrant or heat provisioners._

## 2. defaults.yml

There are a large number of settings that do not change across environments, to
ensure we don't have to copy/paste the same data into dozens (or more!) Inventories
we have a shared `defaults.yml` file in the base of the inventory repository.

We have a custom Ansible [vars plugin](plugins/vars/default_vars.py) that looks this
file up based on a setting `var_defaults_file = ../defaults.yml` in `ansible.cfg`.

## 3. Ansible variable naming scheme

In general Ansible does not do a great job of protecting a role's variables and
any role can override a variable intented for another role, this causes great fun
when using roles that other people have written.

To avoid this we built a convention of namespacing our role's variables by giving
each role its own dictionary named for itself) and we use the ansible/python
dictionary merging behaviors to our benefit (and sometimes to our detriment)
by setting `hash_behaviour = merge` in our `ansible.cfg`.

Thus our apache role's variables are always under the apache namespace for example:

```
apache:
  modules:
    - libapache2-mod-wsgi
  listen: []
```

and would be accessed in the role's tasks like so:

```
- name: install apache module packages
  apt:
    pkg: "{{ item }}"
  register: result
  until: result|succeeded
  retries: 5
  with_items: "{{ apache.modules }}"
```

The community in the meantime has gone with a convention of snakecase for variable
naming such as `apache_modules: []` instead of `apache.modules: []`.  We find
the dictionary method to be easier to read for a human when looking at an inventory.

This does have its perils:

1. It is fairly easy to create a dictionary merge issue which causes Ansible to
 drop the dictionary completely rather than hard failing. This causes weird
 issues where the playbook runs fine until it hits something needed
from that dictionary (often in a template) and it fails because it can't find
the specified version.

2. Hashes merge, lists do not.  You cannot [easily] add a item to a list, you have
to rewrite the whole list.  Similarly if you have a dictionary in `defaults` and
try to override it in `group_vars/all` by removing a key, it will not actually remove
it. It's easy to forget these behaviors and end up with an unexpected behavior.
This is why some of our dictionaries are set empty in the roles defaults and are
defined for the first time in `defaults` or deeper into the inventory.

## 4. Wrapper roles

We have found it useful to utilize wrapper roles for things that we do often and
treat them as if they were quasi-modules. This helps us to ensure that our
roles are easily composable. Two examples of this are the `apt-repos`
and `sensu-checks` roles.  Both contain a lookup dictionary in their defaults
and tasks to perform actions on them.  `apt-repos` is also a good example of
where we provide a blank dictionary in the role and expect them to be filled out
correctly in the inventory.

The `apt-repos` role utilizes a dictionary of all the known apt repositories that
are needed to install various software by their roles (example sensu) and by
calling the `apt-repos` role from within a role we install the repo and its key
into apt sources:

```
dependencies:
  - role: apt-repos
    repos:
      - repo: "deb {{ apt_repos.sensu.repo }} {{ ansible_distribution_release }} main"
        key_url: '{{ apt_repos.sensu.key_url }}'
```

When the sensu role is run it passes the `repos` list to the `apt-repo` role which
then calls the `apt_repository` and `apt_key` modules to configure the apt repo
on the systems.
