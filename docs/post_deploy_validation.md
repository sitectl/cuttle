# Validating a SoftLayer Remote Site Controller

##### 1. Run network tests

```
$ ursula ../sitecontroller-envs/remote-$DC playbooks/healthcheck.yml
```

##### 2. Ensure datacenter is visible in control

Go to https://control.XXXXX.com/ and verify your datacenter is listed in "Remote Locations".

##### 3. Can reach PagerDuty

ssh to `monitor01` and `elk01`, stop `sensu-client`, and ensure central and remote Sensu servers were notified.

```
$ ssh -F ../sitecontroller-envs/remote-$DC/ssh_config monitor01
$ service sensu-client stop

$ ssh -F ../sitecontroller-envs/remote-$DC/ssh_config elk01
$ service sensu-client stop
```
Proceed to https://control.XXXXX.com/ and click Sensu under "Locations" and "Remote Locations".
You should see an alert in both places for the downed clients. Don't forget to start them when you're done.
```
$ service sensu-client start
```
Go to https://control.XXXXX.com/flapjack and verify your datacenter is listed in "Entities".

##### 4. Can reach Grafana

Go to https://control.XXXXX.com/ and click on the "Grafana" link for your datacenter.
You should see the Grafana dashboard, and Graphite should be listed as a data source.

##### 5. Can reach Kibana

Go to https://control.XXXXX.com/ and click on the "Kibana" link for your datacenter.
You should see a bunch of logs.

##### 6. Can reach Uchiwa

Go to https://control.XXXXX.com/ and click on the "Sensu" link for your datacenter.
There should be no error messages. Click on "Datacenter" on the left and you should see your datacenter as "connected".

##### 7. Central Uchiwa can reach remote sensu-api

Go to https://control.XXXXX.com/sensu/#/datacenters and verify your datacenter is listed and "connected".
