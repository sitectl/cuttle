# {{ ansible_managed }}

require 'spec_helper'
{% for key,value in sensu.server.handlers|dictsort %}
{% if value.enabled is defined %}
{% if value.enabled %}

describe file('/etc/sensu-server/conf.d/handlers/{{ key }}.json') do
  it { should be_file }
end
{% if value.uri is defined %}
describe file('/etc/sensu-server/conf.d/handlers/{{ key }}.json') do
  its(:content) { should contain("{{ value.uri }}") }
end
{% endif %}
{% endif %}
{% endif %}
{% endfor %}
{% for key,value in sensu.server.handlers.hijack|dictsort %}
{% if value|length > 0 %}

describe file('/etc/sensu-server/conf.d/handlers/{{ key }}_hijack.json') do
  it { should be_file }
end
{% endif %}
{% endfor %}
