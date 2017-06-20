# Pypi-mirror role

## devpi

PyPi Proxy/Mirror

Apache is fronting it,  if mirror already has a files Apache will serve it directly,  if not, it will refer to pypi which will feed metadata and proxy/mirror the appropriate wheel from Pypi.

Can also be used for private pip repos ... but not implemented via ansible yet.

To use once set up do:

### ~/.pip/pip.conf
```
[global]
index-url = http://mirror01.local:81/root/pypi/+simple/
```

### ~/.pydistutils.cfg
```
[easy_install]
index_url = http://mirror01.local:81/root/pypi/+simple/
```

## bandersnatch

depreciated ...  going away.

