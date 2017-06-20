# {{ ansible_managed }}

require 'spec_helper'

describe user('graphite') do
  it { should exist }	#GPH001
  it { should belong_to_group 'graphite' }	#GPH002
  it { should have_home_directory '/nonexistent'}	#GPH003
  it { should have_login_shell '/bin/false' }	#GPH004
end

describe file('{{ graphite.path.home }}/conf') do
  it { should be_mode 755 }	#GPH005
  it { should be_owned_by 'graphite' }	#GPH006
  it { should be_directory }	#GPH007
end

describe file('{{ graphite.path.home }}/conf/carbon.conf') do
  it { should be_mode 644 }	#GPH008
  it { should be_owned_by 'graphite' }	#GPH009
  it { should be_file }	#GPH010
end

describe file('{{ graphite.path.home }}/conf/storage-schemas.conf') do
  it { should be_mode 644 }	#GPH011
  it { should be_owned_by 'graphite' }	#GPH012
  it { should be_file }	#GPH013
{% for name, params in graphite.storage_schemas.items() %}
  file_contents = ['[{{ name }}]',
                   '# {{ params.comment }}',
{% if name != "carbon" %}
                   'pattern = {{ params.pattern }}',
{% endif %}
                   'retentions = {{ params.retentions }}']
  file_contents.each do |file_line|
    its(:content) { should contain(file_line) }   #GPH014
  end
{% endfor %}
end

describe file('{{ graphite.path.home }}/conf/graphite.wsgi') do
  it { should be_mode 644 }	#GPH015
  it { should be_owned_by 'graphite' }	#GPH016
  it { should be_file }	#GPH017
end

describe file('{{ graphite.path.virtualenv }}/bin/carbon-cache.py') do
  it { should be_mode 755 }	#GPH018
  it { should be_owned_by 'root' }	#GPH019
  it { should be_file }	#GPH020
end

describe file('{{ graphite.path.install_root }}/webapp/graphite/storage.py') do
  it { should be_mode 644 }	#GPH021
  it { should be_owned_by 'root' }	#GPH022
  it { should be_file }	#GPH023
end

describe file('{{ graphite.path.install_root }}/webapp/graphite/local_settings.py') do
  it { should be_mode 644 }	#GPH024
  it { should be_owned_by 'root' }	#GPH025
  it { should be_file }	#GPH026
end

describe file('/etc/init/carbon-cache.conf') do
  it { should be_file }	#GPH027
end

describe file('/etc/apache2/sites-available/graphite.conf') do
  it { should be_file }	#GPH029
end

describe file('/var/log/graphite') do
  it { should be_owned_by 'graphite' }	#GPH031
  it { should be_grouped_into 'graphite' }	#GPH032
  it { should be_directory }	#GPH033
end

describe service('carbon-cache') do
  it { should be_enabled }
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end
