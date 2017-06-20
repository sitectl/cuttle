backend "{{ vault.backend.store }}" {
  address = "{{ vault.backend.address|default("127.0.0.1") }}:{{ vault.backend.port|default("8500") }}"
  path = "{{ vault.backend.path|default("vault") }}"
}

listener "tcp" {
  address = "{{ hostvars[inventory_hostname]['ansible_' + vault.bind_interface].ipv4.address }}:{{ vault.bind_port }}"
  {% if vault.tls.enabled %}
  tls_disable = 0
  tls_cert_file = "{{ vault.tls.cert_file }}"
  tls_key_file = "{{ vault.tls.key_file }}"
  {% else %}
  tls_disable = 1
  {% endif %}
}

{% if vault.telemetry.enabled %}
telemetry {
  statsd_address = "{{ statsd_address }}:{{ statsd_port }}"
}
{% endif %}
