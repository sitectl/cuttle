# Bastion User Admin

This document provides a comprehensive guide to managing access
requests for Bastion systems.

## Workflow

1. edit your ansible inventory and modify your bastion users ( `users:` namespace ).
2. run `site.yml`, `playbooks/add-bastion-users.yml`, or `playbooks/delete-bastion-users.yml`

## Setup

User administation requires the following two repos. Clone both (on a Bastion host), and create a virtualenv
per the instructions [here](https://github.com/IBM/cuttle#build-development-environment).

1. [sitecontroller](https://github.com/IBM/cuttle) contains the code to
add/update/delete users. Important files: `site.yml`, `playbooks/add-bastion-users.yml`, & `playbooks/delete-bastion-users.yml`.

2. Your ansible inventory contains a representation
of all users that currently have access, as well as their access levels.

## bastion-users.yml

There are two data structures of importance in your ansible inventory.

1. `user_groups`

  This is a dictionary of groups. Consider a group to be an access level.
  Users belong to groups, and groups have ssh keys. Certain systems
  permit access to specific ssh keys. Here's a taste:
  ```
  user_groups:
    blueboxadmin:
      system: yes
      ssh_keys:
        enable_passphrase: no
        fingerprint: ~
        public: ~
        private: ~
  ```

2. `users`

  This is a dictionary of Bastion users. A user inherits the keys of the groups he belongs to.
  In other words, when a user logs in, his ssh agent is loaded with the keys of the groups of which he is a member.
  This allows granular, explicit, and auditable control of permissions on Bastion systems. Users also have YubiKey
  data associated with them, which allows for two-factor authentication. `uid` needs to be unique per user. Here's a flavor:
  ```
  users:
    bobsmith:
      comment: "Bob Smith; bobsmith@example.com"
      primary_group: default
      groups:
        - internal_restricted
        - OpenStack_Operations
        - SiteController_Operations
      public_keys:
        - ssh-rsa AAAAB3...
      uid: 1002
      yubikey:
        aes_key: ~
        private_id: ~
        public_id: ~
        serial_number: ~
  ```

## Add & Update Bastion Users

There are two steps that must be taken to add & update Bastion users:

1. Update `bastion-users.yml`
2. Run `playbooks/add-bastion-users.yml` OR `site.yml`

#### Update ansible inventory

Gather following user info:
```
  <username>:
    comment: ...
    primary_group: <default or other group defined above>
    groups:
      - <additional group access> #if applicable
    public_keys:
    - <ssh pub key> #ask user for this
    uid: <next available uid on bastions>
    yubikey:
      aes_key:  <yubi_aes_key>
      private_id: <yubi_private_id>
      public_id: <yubi_public_id>
      serial_number: <yubi_serial_number>
```
Determine username and confirm it doesn't exist on either bastion.
The uid can be determined by running this one-liner on both bastions (disregard the 65534 uid):
```
$ awk -F":" '{ print $3 }' /etc/passwd | sort -n | tail
1113
1114
1115
1116
1117
1118
1119
1120
1121
65534
```
In this example, 1121 is the highest uid in use so the new user will be 1122.

Update `users` and `user_groups` as applicable. Because of the sensitivity of the
data in the `bastion-users.yml`, it is encrypted by [Ansible Vault](http://docs.ansible.com/ansible/playbooks_vault.html).
```
ansible-vault edit bastion-users.yml
<enter Vault password from Box Panel Password Management>
```
For information on diffing encrypted files, please see [here](https://github.com/IBM/cuttle-envs#encrypted-files).

#### Run playbooks/add-bastion-users.yml OR site.yml

This must be done against all datacenters with Bastion hosts. The most efficient way is to use the `add-bastion-users` playbook:
```
ursula ../sitecontroller-envs/control-dc01 playbooks/add-bastion-users.yml --ask-vault-pass --ask-su-pass -e "@../inventory/bastion-users.yml" -e "usernames=bobsmith,pdiddy"
```
If you decide you want to run `site.yml` here are some options:
```
# if only updating users
ursula ../sitecontroller-envs/control-dc01 site.yml --limit=bastion -e "@../inventory/bastion-users.yml" --ask-vault-pass --ask-su-pass --skip-tags support-tools,ssh-agent
<enter Bastion password>
<enter Vault password>

# if updating both users and groups
ursula ../sitecontroller-envs/control-dc01 site.yml --limit=bastion -e "@../inventory/bastion-users.yml" --ask-vault-pass --ask-su-pass --skip-tags support-tools
...
```

## Delete Bastion Users

There are also two steps for deleting Bastion users:

1. Update `bastion-users.yml`
2. Run `playbooks/delete-bastion-users.yml`

```
ursula ../sitecontroller-envs/control-dc01 playbooks/delete-bastion-users.yml --ask-su-pass -e "username=bobsmith"
```
