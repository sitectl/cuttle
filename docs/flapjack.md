# Monitoring and alerting with Flapjack

Flapjack is a event processor that takes messages from multiple sources,
then filters and relays messages to PagerDuty, email or SMS.

For Blue Box Cloud, Sensu clients on OpenStack nodes and site controller
nodes send messages to the Sensu server in the datacenter it is deployed
in. The Sensu server sends messages to a Flapjack server in the central
Site Controller, which applies rules to determine if, and where, to send
an alert.

```text
    OpenStack or SC node                                                          
┌───────────────────────────┐                                                     
│       Sensu Client        │                                                     
└───────────┬───────────────┘                                                     
            │                                                                     
            │ Dedicated or Local SC monitor                                       
            │    ┌─────────────────────┐                                          
            └────▶    Sensu Server     │                                          
                 └────╦────────────────┘                                          
                      ║                                                           
Sensu Flapjack handler║       Central controller                                  
 (HTTP req over VPN)  ║        ┌──────────────┐                                   
                      ╚════════▶              │                                   
                      ╔════════▶   Flapjack   ├────────▶ PagerDuty, email, or SMS
                      ║ ╔══════▶              │                                   
                      ║ ║      └──────────────┘                                   
                      ║ ║                                                         
                      ║ ║                                                         
            Other SC Sensu servers                                                

```

Sensu client checks are created during Ursula playbook runs with the `sensu_check`
Ansible module. A custom field, `service_owner`, a recipient for the check,
can optionally be added with the module. This field is only used by the
[`flapjack_http`][fh] Sensu handler; if omitted, it uses the value `'default'`.
When processing an event, the handler adds a tag `service_owner:value` before sending
to Flapjack.

[fh]: https://github.com/IBM/cuttle/blob/master/roles/sensu-server/files/etc/sensu/extensions/handlers/flapjack_http.rb

In Flapjack, [notification rules][n] are associated with contacts. These notification rules
can match on tags. When an event is received, contacts with matching rules will be notified.
On the central site controller monitoring node, a simple helper script `flapjackadm` allows
you to see how the notification rules are set up. Use `flapjackadm contact list` to see
contacts, and `flapjackadmin contact show --id [ID]` to view notification rules for that
contact. Currently, both `service_owner:default` and `service_owner:openstack` are routed to OpenStack team in PagerDuty.

[n]: http://flapjack.io/docs/1.0/usage/Notification-Routing/

# Add a new contact

```
# ssh to monitor01 host in control-*
ssh -F ...

# list current contacts
flapjackadm contact list

# add new contact
flapjackadm contact add --name 'nope Ops' --email 'nope@example.com' --tags 'service_owner:nope'

# find id of new contact
flapjackadm contact list

# use id of new contact to show it
flapjackadm contact show --id e6c8b9ee-255b-4591-cfc4-71a84691a4b3

# edit default notification rule to disable all alerts
flapjackadm rule edit --rule-id cc1cb568-4f4f-438a-ac12-1cfb95fea889 --rule-warning-media '-' --rule-critical-media '-'

# add new contact method of pagerduty
flapjackadm pagerduty add --id e6c8b9ee-255b-4591-cfc4-71a84691a4b3 --pd-key XXXXXXXX --pd-subdomain example --pd-token XXXXXX

# add notifiction rule for pagerduty matching on the tags 'service_owner:cleversafe' but DO NOT alert on WARNING alerts
flapjackadm rule add --id e6c8b9ee-255b-4591-cfc4-71a84691a4b3 --rule-tags 'service_owner:nope' --rule-critical-media pagerduty --rule-warning-blackhole

# modify following script to use new contact id, adds the magic ALL entity.
ruby add-flapjack-ALL-entity-to-contact-id.rb

cat add-flapjack-ALL-entity-to-contact-id.rb
#!/usr/bin/env ruby
require 'flapjack-diner'
Flapjack::Diner.base_uri('127.0.0.1:3081')

entity_all_data = {
  :id   => 'ALL',
  :name => 'ALL'
}

ada_data = {
  :id         => 'e6c8b9ee-255b-4591-cfc4-71a84691a4b3'
}

entity_all = Flapjack::Diner.entities(entity_all_data[:id]).first
unless entity_all[:links][:contacts].include?(ada_data[:id])
  puts "Adding Contact ID #{ada_data[:id]} to the ALL entity"
  Flapjack::Diner.update_entities(entity_all_data[:id], :add_contact => ada_data[:id])
end
```

# Update a contact's notification_rules

```
# ssh to monitor01 host in control-*
ssh -F ...

# list current contacts and find id of desired contact to modify
flapjackadm contact list

# use id of new contact to show it
flapjackadm contact show --id e6c8b9ee-255b-4591-cfc4-71a84691a4b3

# add notifiction rule for email matching on the tag 'service_owner:openstack' AND tag 'ticket' but DO NOT email on CRITICAL alerts
flapjackadm rule add --id e6c8b9ee-255b-4591-cfc4-71a84691a4b3 --rule-tags 'service_owner:openstack,ticket' --rule-warning-media email --rule-critical-blackhole
```
