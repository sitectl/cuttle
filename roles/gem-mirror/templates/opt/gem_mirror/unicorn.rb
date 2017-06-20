# {{ ansible_managed }}
worker_processes {{ gem_mirror.worker_processes }}
working_directory "{{ gem_mirror.home }}"
listen "{{ gem_mirror.host }}:{{ gem_mirror.port }}"
timeout {{ gem_mirror.timeout }}
pid "{{ gem_mirror.home }}/unicorn.pid"
preload_app true

if(GC.respond_to?(:copy_on_write_friendly=))
  GC.copy_on_write_friendly = true
end
