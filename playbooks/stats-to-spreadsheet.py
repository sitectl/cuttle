#!/usr/bin/python

#
# Usage: stats-to-excel.py <options>
#      options:
#         -a  = compile for all sites for stats that have been collected prior
#         -c  = compare previous stats with current stats
#
#         -s  <site_name>  = target a particular site report
#

import subprocess
import os
import sys, getopt
import pandas
import json

site_names=[]
site = "example_site"
outfile = "elk-stats/report.xls"
compare = False
all_sites = False

def find_files():
  global site_names
  if all_sites:
    command = "ls elk-stats/*current_stats.json | awk -F\- '{print $3}'"
  else:
    command = "ls elk-stats/remote-%s-current_stats.json | awk -F\- '{print $3}'" % site
  search = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE).stdout.read()
  site_names.extend(str(search).split('\n'))
  site_names = site_names[:-1]
  return

def collect():
  report_data = {}
  for sitename in site_names:
    report_data[sitename] = \
      {
        "Days Remaining - Current": None,
        "Last Host Count - Current": None,
        "Last Index Size - Current": None,
        "Retention Days": None
      }
    curr_filename = "elk-stats/remote-" + sitename + "-current_stats.json"
    with open(curr_filename, 'r') as curr_file:
      curr_file_stats = json.load(curr_file)
    report_data[sitename]["Days Remaining - Current"] = \
      float(curr_file_stats["Days Remaining Until Max Capacity Reached"])
    report_data[sitename]["Last Host Count - Current"] = \
      float(curr_file_stats["Last Host Count"])
    report_data[sitename]["Last Index Size - Current"] = \
      float(curr_file_stats["Last Index Size"])
    report_data[sitename]["Retention Days"] = \
      float(curr_file_stats["Retention Days"])
    if compare:
      prev_filename = "elk-stats/remote-" + sitename + "-previous_stats.json"
      with open(prev_filename, 'r') as prev_file:
        prev_file_stats = json.load(prev_file)
      report_data[sitename]["Days Remaining - Previous"] = \
        float(prev_file_stats["Days Remaining Until Max Capacity Reached"])
      adjust = check_value(report_data[sitename]["Days Remaining - Previous"])
      report_data[sitename]["Days Remaining - ROC"] = \
        (float(curr_file_stats["Days Remaining Until Max Capacity Reached"])/\
        (float(prev_file_stats["Days Remaining Until Max Capacity Reached"]) + adjust))
      report_data[sitename]["Last Host Count - Previous"] = \
        float(prev_file_stats["Last Host Count"])
      adjust = check_value(report_data[sitename]["Last Host Count - Previous"])
      report_data[sitename]["Last Host Count - ROC"] = \
        (float(curr_file_stats["Last Host Count"])/\
        (float(prev_file_stats["Last Host Count"]) + adjust))
      report_data[sitename]["Last Index Size - Previous"] = \
        float(prev_file_stats["Last Index Size"])
      adjust = check_value(report_data[sitename]["Last Index Size - Previous"])
      report_data[sitename]["Last Index Size - ROC"] = \
        (float(curr_file_stats["Last Index Size"])/\
        (float(prev_file_stats["Last Index Size"]) + adjust))
  return report_data

def convert(data):
  print("\n%s\n") % data
  pandas.DataFrame.from_dict(data,orient='index').sort_index(axis=1).to_excel(outfile)
  return

def check_value(value):
  if value == 0.0:
    return 1.0
  else:
    return 0.0

def main(argv):
  global site, compare, all_sites
  try:
      opts, args = getopt.getopt(argv,"hs:ca",["site=","compare","all-sites"])
  except getopt.GetoptError:
      print '\nCommand line options for "stats-to-spreadsheet.py":\n\t-s SITE\t\tCompiles report for site specified.\n\t-a\t\tCompiles report for all sites.\n\t-c\t\tIncludes previous stats for comparison.\n'
      sys.exit(2)
  for opt, arg in opts:
      if opt == '-h':
          print '\nCommand line options for "stats-to-spreadsheet.py":\n\t-s SITE\tCompiles report for site specified.\n\t-a\tCompiles report for all sites.\n\t-c\tIncludes previous stats for comparison.\n'
          sys.exit()
      elif opt in ("-s", "--site"):
          site = arg
      elif opt in ("-a", "--all-sites"):
          all_sites = True
      elif opt in ("-c", "--compare"):
          compare = True
  find_files()
  raw_data = collect()
  convert(raw_data)
  return

if __name__ == "__main__":
  main(sys.argv[1:])
