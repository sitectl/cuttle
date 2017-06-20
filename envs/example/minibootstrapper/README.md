# Mini Bootstrapper

Designed to create a Vagrant VM with just enough tooling to bootstrap a bootstrapper.

Once booted and running you need to swap the Virtualbox networking for `adapter 3` to bridged on the physical network interface of your laptop.

It runs a pxeboot server and a squid proxy.   As long as it has internet access ( or VPN tether to the mirrors ) it should be able to get the bootstrapper installed.

There are some tasks in the `pxe` role for setting the mini bootstrapper up to be able to `NAT` traffic.   These are featured flagged off by default, but turned on for the environment.   They are not idempotent,  but that's okay because this is a disposable VM.
