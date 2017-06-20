# {{ ansible_managed }}

require 'spec_helper'
require 'etc'

### tasks/mail.yml

{% for pkg in common.packages %}
describe package('{{ pkg }}') do
  it { should be_installed } #OPS001
end
{% endfor %}

describe file('/etc/timezone') do
  it { should be_file } #OPS002
  it { should contain 'Etc/UTC' } #OPS003
end

{% if common.hwraid.enabled %}
{% for pkg in common.hwraid.add_clients %}
describe package('{{ pkg }}') do
  it { should be_installed } #OPS004
end
{% endfor %}

{% for pkg in common.hwraid.remove_clients %}
describe package('{{ pkg }}') do
  it { should_not be_installed } #OPS005
end
{% endfor %}
{% endif %}

{% if common.mdns.enabled|bool %}
describe package('avahi-daemon') do
  it { should be_installed } #OPS008
end
{% else %}
describe package('avahi-daemon') do
  it { should_not be_installed } #OPS009
end
{% endif %}

{% if common.python.proxy_url|default('False')|bool %}
describe file('/root/.pip/pip.conf') do
  it { should be_file } #OPS010
  it { should contain '{{ common.pip.proxy_url }}' } #OPS011
end
{% endif %}

{% for pkg in common.python.packages %}
{% if not pkg.skip_serverspec|default('False')|bool %}
describe package('{{ pkg.name.split('>')[0] }}') do
  it { should be_installed.by('pip') } #OPS012
end
{% endif %}
{% endfor %}

describe file('/etc/sudoers') do
  its(:content) { should match /^Defaults\s+env_keep\+=SSH_AUTH_SOCK/ } #OPS014
end

describe service('ssh') do
  it { should be_enabled }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match /^PasswordAuthentication no/ } #OPS015
  its(:content) { should_not match /^PasswordAuthentication yes/ } #OPS016
  its(:content) { should match /^PermitRootLogin no/ } #OPS017
  its(:content) { should_not match /^PermitRootLogin yes/ } #OPS018
  its(:content) { should match /^PermitEmptyPasswords no/ } #OPS019
  its(:content) { should_not match /^PermitEmptyPasswords yes/ } #OPS020
  its(:content) { should match /^PubkeyAuthentication yes/ } #OPS021
  its(:content) { should_not match /^PubkeyAuthentication no/ } #OPS022
  its(:content) { should match /^RSAAuthentication yes/ } #OPS023
  its(:content) { should_not match /^RSAAuthentication no/ } #OPS024
  its(:content) { should match /^HostbasedAuthentication no/ } #OPS025
  its(:content) { should_not match /^HostbasedAuthentication yes/ } #OPS026
  its(:content) { should match /^IgnoreRhosts yes/ } #OPS027
  its(:content) { should_not match /^IgnoreRhosts no/ } #OPS028
  its(:content) { should match /^PrintMotd yes/ } #OPS029
  its(:content) { should_not match /^PrintMotd no/ } #OPS030
  its(:content) { should match /^PermitUserEnvironment no/ } #OPS031
  its(:content) { should_not match /^PermitUserEnvironment yes/ } #OPS032
  its(:content) { should match /^StrictModes yes/ } #OPS033
  its(:content) { should_not match /^StrictModes no/ } #OPS034
  its(:content) { should match /^ServerKeyBits 1024/ } #OPS035
  its(:content) { should match /^TCPKeepAlive yes/ } #OPS036
  its(:content) { should_not match /^TCPKeepAlive no/ } #OPS037
  its(:content) { should match /^LoginGraceTime 120/ } #OPS038
  its(:content) { should match /^MaxStartups 100/ } #OPS039
  its(:content) { should match /^LogLevel INFO/ } #OPS040
  its(:content) { should match /^MaxAuthTries 15/ } #OPS041
  its(:content) { should match /^KeyRegenerationInterval 3600/ } #OPS042
  its(:content) { should match /^Protocol 2/ } #OPS043
  its(:content) { should match /^GatewayPorts no/ } #OPS044
  its(:content) { should_not match /^GatewayPorts yes/ } #OPS045
  its(:content) { should match /^UsePAM yes/ } #OPS046
  its(:content) { should_not match /^UsePAM no/ } #OPS047
  its(:content) { should match /^Ciphers aes128-ctr,aes192-ctr,aes256-ctr/ } #OPS092
  its(:content) { should match /^MACs hmac-sha1,hmac-ripemd160/ } #OPS093
{% if common.ssh.disable_dns|bool %}
  its(:content) { should match /^UseDNS no/ } #OPS048
  its(:content) { should_not match /^UseDNS yes/ } #OPS049
{% else %}
  its(:content) { should match /^UseDNS yes/ } #OPS050
  its(:content) { should_not match /^UseDNS no/ } #OPS051
{% endif %}
end

{% for item in common.ssh.private_keys %}
describe file('{{ item.dest }}') do
  it { should be_owned_by '{{ item.owner|default('root') }}' } #OPS052
  it { should be_grouped_into '{{ item.group|default('root') }}' } #OPS053
  it { should be_mode 600 } #OPS054
end
{% endfor %}

describe package('ufw') do
  it { should be_installed } #OPS056
end

describe command('ufw status') do
  its(:stdout) { should match /Status: active/ } #OPS057
end

# FIX THIS TO BE BETTERER
#describe command("ufw show added | sed '1d'") do
#{% for item in common.ssh.allow_from %}
#  {% if item == "0.0.0.0/0" %}
#  its(:stdout) { should match /^ufw allow 22\/tcp$/ }
#  {% else %}
#  its(:stdout) { should match /^ufw allow 22\/tcp/ }
#  {% endif %}
#{% endfor %}
#end

# TEST FOR THIS
#- name: Permit unrestricted access from remainder of cluster
#  ufw: rule=allow from_ip={{ item }} proto=any
#  with_items: common.firewall.friendly_networks


describe file('/etc/default/ufw') do
{% if common.firewall.forwarding|bool %}
  its(:content) { should match /^DEFAULT_FORWARD_POLICY="ACCEPT"/ } #OPS058
{% else %}
  its(:content) { should_not match /^DEFAULT_FORWARD_POLICY="ACCEPT"/ } #OPS059
{% endif %}
end

{% if common.ntpd.enabled|bool %}

['ntp','ntpdate'].each do |pkg|
  describe package(pkg) do
    it { should be_installed } #OPS060
  end
end

describe service('ntp') do
  it { should be_enabled }
end

{% endif %}

describe file('/etc/pam.d/login') do
  its(:content) { should contain /^@include common-auth/ } #OPS062
  its(:content) { should contain /^@include common-account/ } #OPS063
  its(:content) { should contain /^@include common-session/ } #OPS064
  its(:content) { should contain /^@include common-password/ } #OPS065
end

describe file('/etc/pam.d/common-password') do
  its(:content) { should contain /^password\t\[success=1 default=ignore\]\tpam_unix\.so obscure sha512/ } #OPS066
end

describe file('/etc/adduser.conf') do
  its(:content) { should match /^DIR_MODE=([0-7][0-5][0-5]|0[0-7][0-5][0-5])/ } #OPS067
end

files = ['.rhosts','.netrc']
files.each do |file|
  describe file ("~root/#{file}") do
    it { should_not exist } #OPS068
  end
end

files = ['bin', 'boot', 'dev', 'etc', 'home','lib',
         'lib64', 'lost+found', 'media', 'mnt', 'opt', 'proc', 'root',
         'run', 'sbin', 'srv', 'sys', 'usr', 'var']
files.each do |file|
  describe file("/#{file}/") do
    it { should be_directory } #OPS069
    it { should be_mode '[0-7][0-7][0-5]' } #OPS070
  end
end

files = ['bin', 'games', 'include', 'lib', 'local', 'sbin', 'share', 'src']
files.each do |file|
  describe file("/usr/#{file}/") do
    it { should be_directory } #OPS071
    it { should be_mode '[0-7][0-7][0-5]' } #OPS072
  end
end

describe file('/etc/security/opasswd') do
  it { should exist } #OPS073
  it { should be_mode 600 } 	#OPS074
end

describe file('/etc/shadow') do
  it { should exist } #OPS075
  it { should be_mode 640 } #OPS076
end

files = ['backups', 'cache', 'lib', 'local',
         'log', 'mail', 'opt', 'spool']
files.each do |file|
  describe file("/var/#{file}/") do
    it { should be_directory } #OPS077
    it { should be_mode '[0-2]*[0-7][0-7][0-5]' } #OPS078
  end
end

describe file('/var/tmp/') do
  it { should be_directory } #OPS079
end

files = ['syslog', 'auth.log']
files.each do |file|
  describe file ("/var/log/#{file}") do
    it { should exist } #OPS080
    it { should be_mode '[0-7][0-5][0-5]' } #OPS081
    it { should be_owned_by 'syslog' }  #OPS082
  end
end

describe file('/tmp/') do
  it { should be_directory } #OPS083
end

files = ['/etc/init/', '/var/spool/cron/', '/etc/cron.d/', '/etc/cron.d/sysstat', '/etc/init.d/', '/etc/rc0.d/',
         '/etc/rc1.d/', '/etc/rc2.d/','/etc/rc3.d/','/etc/rc4.d/','/etc/rc5.d/','/etc/rc6.d/','/etc/rcS.d/']
files.each do |file|
  describe file("#{file}") do
    it { should be_mode '[0-7][0-7][0-5]' } #OPS084
  end
end

files = ['/', '/usr', '/etc', '/etc/security/opasswd',
         '/etc/shadow', '/var', '/var/tmp', '/var/log',
         '/var/log/wtmp', '/tmp']
files.each do |file|
  describe file(file) do
    it { should be_owned_by 'root' } #OPS085
  end
end

#describe file('/etc/login.defs') do
#  its(:content) { should match /^PASS_MAX_DAYS   90/ }
#  its(:content) { should_not match /^PASS_MAX_DAYS   99999/ }
#  its(:content) { should match /^PASS_MIN_DAYS   1/ }
#  its(:content) { should_not match /^PASS_MIN_DAYS   0/ }
#end

describe file('/etc/sudoers.d/blueboxcloud') do
  it { should be_mode 744 } #OPS086
  it { should be_owned_by 'root' } #OPS087
  it { should be_grouped_into 'root' } #OPS088
  it { should be_file } #OPS089
{% for sudoer in common.sudoers %}
{% for arg in sudoer.args %}
  its(:content) { should contain('{{ sudoer.name }} {{ arg }}'.gsub(/[()]/){ |c| "\\" << c }) } #OPS090
{% endfor -%}
{% endfor %}
end

{% if groups['bastion'] is defined and inventory_hostname in groups['bastion'] %}
describe command('grep -r "blueboxadmin\sALL=(ALL)\sNOPASSWD:ALL" /etc/sudoers.d/') do
  its(:stdout) { should_not contain('blueboxadmin') } #OPS091
end
{% endif %}

{% if groups['ttyspy-server'] is defined and inventory_hostname in groups['ttyspy-server'] %}
describe command('grep -r "blueboxadmin\sALL=(ALL)\sNOPASSWD:ALL" /etc/sudoers.d/') do
  its(:stdout) { should_not contain('blueboxadmin') } #OPS091
end
{% endif %}
