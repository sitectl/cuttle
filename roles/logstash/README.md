# Logstash

## Variables

To configure `ufw` rules for your logstash configs:
```yaml
logstash:
  firewall:
    - port: 1514
      protocol: tcp
      src:
        - 127.0.0.1/8
```
