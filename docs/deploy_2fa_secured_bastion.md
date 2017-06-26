# Deploying a 2FA enabled Bastion

One of the core compontents of Cuttle is the two factor enabled secure Bastion.
This document will talk through how to use the composable nature of Cuttle to
install just the necessary parts to create a secure Bastion with two factor
authentication and secure logging.

We will deploy two bastion servers for HA that utilize Google Authenticator
for 2FA and sshagentmux for group based access control.  To do this we will
use Vagrant and the `envs/example/bastion` inventory. Take the time to
explore the inventory files in that directory before starting.

Ordinarily you would use `ansible-vault` to encrypt the variables found in here,
especially the ones that include keys and passwords, however for the sake of
demonstration they're left plain text here.

Before we set up the 2 Factor Authentication we will kick of a basic install of
Bastion and Logging servers.

```
$ ursula --provisioner=vagrant envs/example/bastion site.yml
ringing machine 'ttyspy01' up with 'virtualbox' provider...
Bringing machine 'bastion01' up with 'virtualbox' provider...
Bringing machine 'bastion02' up with 'virtualbox' provider...
...
...
```

## Explore user management

Cuttle creates users on your machines based on the `users` and `user_groups`
sections of your ansible inventory.  Both are fairly straight forward in their
content and have some extra settings for bastion like servers.

If you set `_users.manage_authorized_keys: true` then instead of placing the user's
`authorized_keys` files in their `~/.ssh` like normal it places them in a root only
writable location `/etc/ssh/authorized_keys` which means the users need to provide
their public keys via ansible inventory and cannot modify them on the system themselves.
This is accomplished by the setting `AuthorizedKeysFile /etc/ssh/authorized_keys/%u.keys`
in sshd_config.

Because we did this in the example we also had to set a `vagrant` user in the
users variable so that we could add its public key back in.

You can even set `common.ssh.github_authorized_keys` which enabled a very
rudimentary script that scrapes the github API upon login to grab the user's
valid public keys.  This is very useful for dev enivornments, but ties your
ability to login to the availability of the github api.  It is turned off in
this example.

## Explore group based access controls with sshagentmux

[sshagentmux](https://github.com/blueboxgroup/sshagentmux) is a tool written by
the Blue Box team to emulate a ssh-agent and provide an private keys via
ssh-agent to a user based on group membership. Giving them access to the keys
via ssh-agent allows it to keep the user from ever viewing or changing the key.

private and public keys are assigned to groups in the `user_groups` variable in
the ansible inventory (it can even support keys with passphrases) and then flow
onto the users who are in those groups.

This means that I can restrict access to groups of servers by having an `admin`
user and adding the `admin` group's public key to its `authorized_keys`.

### Demonstrate ACLs with sshagentmux

```
$ ssh -F envs/example/bastion/.ssh_config bobsmith@bastion01               
bobsmith@bastion01:~$ ssh-add -l
2048 ee:53:dc:40:87:49:6e:96:88:3d:02:5d:ca:f2:ac:c6 pczarkowski@czark (RSA)
2048 64:f3:60:f0:33:ed:8b:a3:af:33:c3:c1:e6:c8:41:bf /root/.ssh/admin-id_rsa (RSA)
bobsmith@bastion01:~$ exit
```

You'll see in the above I have two keys in my agent.  One is forwarded from my
desktop (the ssh config that we created from the Vagrantfile has agent
forwarding enabled) and the other key is my admin group's key.

Try to view that key!  you can't.

We have created an `admin` user in our `users` dictionary with this public key
in its authorized_keys, so you should be able to ssh into one of the other
servers using this key:

```
ssh -F envs/example/bastion/.ssh_config bobsmith@bastion01               
bobsmith@bastion01:~$ ssh admin@ttyspy01
Welcome to Ubuntu 14.04.5 LTS (GNU/Linux 3.13.0-117-generic x86_64)
admin@ttyspy01:~$ exit
bobsmith@bastion01:~$ exit
```

## Explore ttyspy

[ttyspy](https://github.com/IBM/ttyspy) is a fairly simple concept that emulates
the linux [script](https://linux.die.net/man/1/script)
command to log sessions, but instead of logging to a file it sends it over a
TLS secured connection to the ttyspyserver.  _It can nearly be done by tying `script`
and `netcat` (or `curl -X POST`) together with a named pipe._

The server is a fairly simple daemon that is run by an installed service.  the
client is made up of two parts a daemon that drops a socket file and a
`ForceCommand` config setting in `/etc/ssh/sshd.conf` that forces all `ssh`
connections to pipe through ttyspy.

You can set a backdoor (`bastion.backdoor_user: vagrant`) user in your ansible
inventory that skips the `ForceCommand` and thus logging/2fa etc.  This can be
useful for the initial setup or for dev work, but we recommend against doing
it in production use cases unless you are very careful.

Both the TTY Spy client and Servers have TLS keys which are secured by a common
CA certificate.  The ones in the example inventory we're using was generated via
the command `docker run -ti -e SSL_SUBJECT=server.test paulczar/omgwtfssl`
and we set the ansible variable `etc_hosts` to fake out DNS for this ttyspy
server so that we don't have to fight TLS with IP addresses.

In this example we are putting our session transcripts in `/tmp/transcripts` which
is not particularly secure.  We can quite easily put it in an encrypted volume,
one that is encrypted before cuttle is run, or by utilizing the `mange_disks` role
which can create `luks` encrypted `LVM` volumes.

### Demonstrate ttyspy

SSH into a bastion server and run some commands, since we set a backdoor for the
vagrant user we'll need to use the `bobsmith` user we created:

```
$ ssh -F envs/example/bastion/.ssh_config bobsmith@bastion02
$ echo hello
$ cat /etc/passwd
$ exit
```

Now we'll check out the logs for the session we just had on bastion02:

_each user session gets its own log file based on the date-time of the login._

```
$ vagrant ssh ttyspy01
vagrant@ttyspy01:~$ sudo cat /tmp/transcripts/bobsmith/bastion02/2017/06/25/transcript_2017-06-25T18\:22\:06Z_308648827
Username: bobsmith
GECOS: Bob Smith; bobsmith@example.com
Hostname: bastion02
Session started: 2017-06-25T18:22:06Z
SSH_Client: 10.0.2.2 53914 22
bobsmith@bastion02:~$ echo hello
hello
bobsmith@bastion02:~$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...
bobsmith@bastion02:~$ exit
logout
Session ended: 2017-06-25T18:22:13Z
```

## Explore 2 Factor Authentication

2FA is achieved by utilizing either Google Authenticator or yubikeys.

The easiest of the options is Google Authenticator as there are plenty of
OTP clients to use, including the Google Authenticator phone app.

To enable 2FA for the `bobsmith` user we can do a
targeted ansible run by setting the necessary tags and setting the
`twofa_enabled` variable.

```
$ ursula --provisioner=vagrant envs/example/bastion \
  site.yml --tags ssh,google-2fa \
  -e "twofa_enabled=true" \
  -e "usernames=bobsmith"
```

_The `twofa_enabled` variable we set above is a shortcut in the bastion
inventory so that we can easily toggle it on and is not how you would normally
enable 2fa_

We preload the google authenticator details in the `users` variable in inventory
and host the files in a directory that only root can read so that users cannot
remove or mess with their google authenticator id.

You can create google authenticator keys needed for the inventory by running
the command `$ google-authenticator -t -d -f -r 3 -R 30 -W` on a machine with
the google authenticator pam module already installed.  This will output a URL
and a QR Code that the user you've created can access/scan to set up their
2fa client.

Since I have an example 2fa code for the `bobsmith` user you can just browse
[here](https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=otpauth://totp/vagrant@bastion01%3Fsecret%3DJEPXZJ3HSYNHMDQO)
to set up your google authenticator client for it.

For this demo we have enabled `nullok` in our inventory so that the vagrant user
can login without 2fa, in production you would probably want to disable `nullok`.

### Demonstrate 2 Factor Authentication

```
ssh -F envs/example/bastion/.ssh_config bobsmith@bastion01
Verification code:
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

bobsmith@bastion01:~$
```
