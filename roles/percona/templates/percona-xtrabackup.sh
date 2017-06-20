#!/bin/bash
#
# {{ ansible_managed }}
#
# File: percona-xtrabackup.sh
#
# Purpose:  This script uses percona's innobackupex script to create db archives.
#
#           $backup_retention_num is the number of full archives that will reside on disk.
#           The desired frequency is up to you and should be defined via cron.
#
#           Note:
#             - To extract Percona XtraBackup‘s archive you must use tar with -i option
#             - To restore an archive, you must use innobackupex with --apply-log option (--apply-log can be ran whenever and does not require a running mysql instance)
#           For more info on using innobackup see: http://www.percona.com/doc/percona-xtrabackup/2.1/innobackupex/innobackupex_option_reference.html
#
# Author: mpatterson@bluebox.net

set -o errexit

email=team-infrastructure@bluebox.net
backup_script=/usr/bin/innobackupex
gzip=/bin/gzip

# The number of full archives to keep.
#
# default value is 7. when ran every 24 hours, this
# provides 7 full archives, for up to 7 days.
backup_retention_num=7

# set & ensure the backup root dir exists
backup_root_dir=/backup/percona/
/usr/bin/test -d $backup_root_dir || /bin/mkdir -p $backup_root_dir

# get list of existing backups.
# innobackupex timestamp format: 2014-01-14_18-43-21
backup_list=($(/bin/ls -urt $backup_root_dir | /bin/grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' || /bin/echo ""))

# create a new db archive, use tar stream to compress on the fly
$backup_script --user=root --stream=tar $backup_root_dir | $gzip - > $backup_root_dir`/bin/date +"%Y-%m-%d_%H-%M-%S"`.tar.gz || (/bin/echo "failed to create db archive at: `/bin/date`" | mail $email -s "Pecona backup failed")

# clean up: delete any archives that exceed the $backup_retention_num
if [ "$#backup_list[@]" -ge "$backup_retention_num" ]; then

  # this should always be true, but let's be paranoid and ensure 100% that the $backup_list
  # index value isn't empty, which would result in deleting the entire $backup_root_dir...
  if [ "$backup_root_dir$backup_list[0]" != "$backup_root_dir" ]; then
    # delete the oldest backup...
    /bin/echo deleting $backup_root_dir${backup_list[0]}
    /usr/bin/test -f $backup_root_dir${backup_list[0]} && /bin/rm -f $backup_root_dir${backup_list[0]}
  fi
fi
