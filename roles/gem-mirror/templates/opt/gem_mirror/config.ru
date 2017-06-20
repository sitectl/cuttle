# {{ ansible_managed }}

require "rubygems"
require "geminabox"

Geminabox.data = "{{ gem_mirror.mirror_location }}"
Geminabox.rubygems_proxy = {{ gem_mirror.rubygems_proxy | lower }}
Geminabox.allow_remote_failure = {{ gem_mirror.allow_remote_failure | lower }}
Geminabox.ruby_gems_url = "{{ gem_mirror.ruby_gems_url }}"

run Geminabox::Server
