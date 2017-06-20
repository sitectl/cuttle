#!/usr/bin/env python2
import paramiko
import optparse
import time
import yaml
import sys


class Ucs_bmc:
  def __init__(self, client=None, shell=None):
    self.shell = shell
    self.client = client
    self.fixkeys = []
 
  def connect(self, options):
    # Create instance of SSHClient object
    self.client = paramiko.SSHClient()
  
    # Automatically add untrusted hosts (make sure okay for security policy in your environment)
    self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
  
    # initiate SSH connection
    self.client.connect(options.ip, username=options.username, password=options.password)
    print "--- SSH connection established to %s ---" % options.ip

  
    # Use invoke_shell to establish an 'interactive session'
    self.shell = self.client.invoke_shell(term='vt102')
    self.shell.setblocking(0)
    print "--- Interactive SSH session established ---"

    output = self.recv(1024)
    # print output

    return self.shell
  
  
  def recv(self, recv_bytes, wait=1):
    # Wait for the command to complete
    # time.sleep(wait)
    time_check = 0
    # print "### recv: start"
    while not self.shell.recv_ready():
      time.sleep(1)
      time_check+=1
      # print "### recv: loop"
      if time_check >= 10:
        print 'time out'#TODO: add exception here
        return

    output = self.shell.recv(recv_bytes)
    # print "### recv: output"
    # print output

    return output


  def run_command(self, command, wait=1, recv_bytes=50000, yml=False):
    # Now let's try to send the cimc a command
    self.shell.send(command + " \n")

    output = self.recv(recv_bytes, wait=wait)

    # strip off first line of output, our command
    fline = output.find('\n')
    output = output[fline+1:]
    # print "### run_command: ["+output+"]"
    # print output

    # if we didn't actually get anything back, try again
    attempt = 0
    while output == "":
      output = self.recv(recv_bytes, wait=wait)
      attempt+=1
      if attempt > 10:
        print "ERROR: could not get data for command: "+command
        break

    # strip off last line of output, cli prompt
    lline = output.rfind('\n')
    output = output[:lline]

    if yml:
       output = yaml.load(output)
    return output


  def check_settings(self, name, expect, actual):
    if actual is None:
      print "ERROR: No actual data from CIMC for %s" % name
      return
    diffkeys = [k for k in expect if expect[k] != actual[k]]
    if len(diffkeys) > 0:
      print "ERROR: %s does not match expectations" % name
      for k in diffkeys:
        err = name + '[' + k + ']: ' + expect[k] + ' != ' + actual[k]
        self.fixkeys.append(err)
        print err
    else:
      print "OK: %s" % name
  
  
  def disable_paging(self):
    '''Disable paging on a Cisco router'''
    self.shell.send("terminal length 0\n")
    time.sleep(1)
  
    # Clear the buffer on the screen
    output = self.shell.recv(1000)
  
    return output


if __name__ == '__main__':
  parser = optparse.OptionParser()
  parser.add_option('-i', '--ip',dest="ip",
              help="[Mandatory] UCSS IP Address")
  parser.add_option('-u', '--username',dest="username",
              help="[Mandatory] Account Username for UCS Login")
  parser.add_option('-p', '--password',dest="password",
              help="[Mandatory] Account Password for UCS Login")

  (options, args) = parser.parse_args()
  
  if not options.ip:
    parser.print_help()
    parser.error("Provide UCS IP Address")
  if not options.username:
    parser.print_help()
    parser.error("Provide UCS Username")
  if not options.password:
    options.password=getpassword("UCS Password")
 
  ucs = Ucs_bmc()
  shell = ucs.connect(options)

  # Turn off paging
  # disable_paging(shell)

  # all output in yaml, for easy parsing
  ucs.run_command("set cli output yaml")

  # check ipmi
  ipmi = ucs.run_command("show ipmi detail", yml=True)
  e_ipmi = {
    "enabled": True,
    "privilege-level": "admin"
  }
  ucs.check_settings('ipmi', e_ipmi, ipmi)

  # check sol
  sol = ucs.run_command("show sol detail", yml=True)
  e_sol = {
    "enabled": True,
    "baud-rate": 115200,
    "comport": "com0"
  }
  ucs.check_settings('sol', e_sol, sol)

  # check bios
  ucs.run_command("top")
  bios = ucs.run_command("show bios detail", yml=True, wait=2)
  e_bios = {
    "boot-order": "HDD,PXE",
    "secure-boot": "disabled",
    "act-boot-mode": "Legacy"
  }
  ucs.check_settings('bios', e_bios, bios)

  # check advanced bios
  ucs.run_command("top")
  ucs.run_command("scope bios")
  ucs.run_command("scope advanced")
  bios_adv = ucs.run_command("show detail", yml=True, wait=2)
  e_bios_adv = {
    "AllLomPortControl": "Disabled"
  }
  ucs.check_settings('bios advanced', e_bios_adv, bios_adv)

  # check power-cap-config
  ucs.run_command("top")
  ucs.run_command("scope chassis")
  ucs.run_command("scope power-cap-config")
  pcc = ucs.run_command("show detail", yml=True)
  e_pcc = {
    "run-pow-char-at-boot": False
  }
  ucs.check_settings('power-cap-config', e_pcc, pcc)

  if len(ucs.fixkeys) > 0:
    print "ERROR: Found items to be fixed."
    for fix in ucs.fixkeys:
      print fix 
    exit(1)
