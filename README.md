# Cuttle

_Originally called Site Controller (sitectl) and is Pronounced "Cuddle"._

_insert logo of a squid/cuttlefish cuddling a server_

A Monolithic Repository of Composable Ansible Roles for building an SRE Operations Platform.

Originally built by the BlueBox Cloud team to install the infrastructure required to build and
support Openstack Clouds using [Ursula](http://github.com/blueboxgroup/ursula) it quickly grew into
a larger project for enabling SRE Operations both in the Datacenter and in the Cloud.

Like Ursula, [Ursula](http://github.com/blueboxgroup/ursula) Cuttle uses the
[ursula-cli](https://github.com/blueboxgroup/ursula-cli) ( installed via requirements.txt )
for running Ansible on specific environments.

For a rough idea of how Blue Box uses Cuttle by building Central and Remote sites
tethered together with IPSEC VPNs check out [architecture.md](architecture.md).

You will see a number of example Ansible Inventories in `envs/example/` that
show Cuttle being used to build infrastructure to solve a number of problems.
`envs/example/sitecontroller` shows close to a full deployment, whereas
`envs/example/mirror` or `envs/example/elk` to build just specific components.
All of these environments can easily be deployed in Vagrant by using the `ursula-cli`
 (see [Example Usage](#example-usage) ).

How to Contribute
-----------------

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for the original team.

The official git repository of Site Controller is https://github.com/IBM/cuttle.
If you have cloned this from somewhere else, may god have mercy on your soul.

### Workflow

We follow the standard github workflow of Fork -> Branch -> PR -> Test -> Review -> Merge.

The Site Controller Core team is working to put together guidance on contributing and
governance now that it is an opensource proect.

Development and Testing
-----------------------

### Build Development Environment

```
# clone this repo
$ git clone git@github.com:ibm/cuttle.git

# install pip, hopefully your system has it already
# install virtualenv
$ pip install virtualenv

# create a new virtualenv so python is happy
$ virtualenv --no-site-packages --no-wheel ~/<username>/venv

# activate your new venv like normal
$ source ~/<username>/venv/bin/activate

# install ursula-cli, the correct version of ansible, and all other deps
$ cd cuttle
$ pip install -r requirements.txt

# run ansible using ursula-cli; or ansible-playbook, if that's how you roll
$ ursula envs/example/<your env> site.yml

# decactivate your virtualenv when you are done
$ deactivate
```

[Vagrant](https://www.vagrantup.com/) is our preferred Development/Testing framework.

### Experimental molecule support

```
# clone this repo
$ git clone git@github.com:ibm/cuttle.git

# install pip, hopefully your system has it already
# install virtualenv
$ pip install virtualenv

# create a new virtualenv so python is happy
$ virtualenv --system-site-packages --no-wheel ~/<username>/venv

# activate your new venv like normal
$ source ~/<username>/venv/bin/activate

# install ursula-cli, the correct version of ansible, and all other deps
$ cd cuttle
$ pip install -r requirements-molecule.txt

# run molecule to deploy dev env for mirror
$ molecule converge --scenario-name mirror

# cleanup
$ molecule destroy --scenario-name mirror
$ deactivate
```

### Example Usage

ursula-cli understands how to interact with vagrant using the `--provisioner` flag:

```
$ ursula --provisioner=vagrant envs/example/sitecontroller bastion.yml
$ ursula --provisioner=vagrant envs/example/sitecontroller site.yml
```

### Openstack and Heat

_your inventory must have a `heat_stack.yml` and a optional `vars_heat.yml` in order for this to work_

You can also test in Openstack with Heat Orchestration. First, grab your stackrc file from Openstack Horizon:

`Project > Compute > Access & Security > Download OpenStack RC File`

Ensure your `ssh-agent` is running, then source your stackrc and run the play:
```
$ source <username>-openrc.sh
$ ursula --ursula-forward --provisioner=heat envs/example/sitecontroller site.yml
```

Add argument `--ursula-debug` for verbose output.

## Run behind a docker proxy for local dev

```
$ docker run  \
  --name proxy -p 3128:3128 \
  -v $(pwd)/tmp/cache:/var/cache/squid3 \
  -d jpetazzo/squid-in-a-can
```

then set the following in your inventory (`vagrant.yml` in `envs/example/*/`)

```
env_vars:
  http_proxy: "http://10.0.2.2:3128"
  https_proxy: "http://10.0.2.2:3128"
  no_proxy: localhost,127.0.0.0/8,10.0.0.0/8,172.0.0.0/8

```

Deploying
---------

To actually deploy an environment you would use ursula-cli like so:

```
$ ursula ../sitecontroller-envs/sjc01 bastion.yml
$ ursula ../sitecontroller-envs/sjc01 site.yml

# targetted runs using any ansible-playbook option
$ ursula ../ursula-infra-envs/sjc01 site.yml --tags openid_proxy
```
