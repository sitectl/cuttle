# Disk Replacement

### MegaCLI Cheatsheets

1. http://erikimh.com/megacli-cheatsheet/
2. https://things.maths.cam.ac.uk/computing/docs/public/megacli_raid_lsi.html

### Disable Shard allocation (BOMv2 ELK Hosts ONLY)
```
curl -XPUT localhost:9200/_cluster/settings -d '{
    "transient" : {
        "cluster.routing.allocation.enable": "none"
    }
}'
```

### Shutdown services (BOMv2 ELK Hosts ONLY)
```
sudo su -
service apache2 stop
service kibana stop
service logstash stop
service elasticsearch stop
```

### Find the bad disk
```
megacli -PDList -aALL | less -> Media & Other Error Count > 0
megacli -ldinfo -Lall -aall | less -> Bad Blocks Exist = Yes
```
Note the `Enclosure Device ID` & `Slot Number` for later. For example:
```
Enclosure Device ID: 9 –> E
Slot Number: 2 –> S
```

### Map the physical disk to the logical disk
```
lshw -class disk
```
You should see something like `physical id: 2.2.0` or `physical id: 2.3.0`.
These correspond to slot number 2 and 3, respectively. Use the slot number
from above to find the correct disk, then note the logical name. For example,
`logical name: /dev/sdc` (Note for later: c -> Z). Once your know this, run `lsblk`.
```
lsblk

sdc                                  8:32   0   1.8T  0 disk
└─sdc1                               8:33   0   1.8T  0 part
  └─vgdata2-lvdata2 (dm-1)         252:1    0   1.8T  0 lvm
    └─luks-vgdata2-lvdata2 (dm-7)  252:7    0   1.8T  0 crypt /data2
```
Save the number next to `vgdata` and `lvdata`: 2 -> X.

### Unmount the partitions from the failed disk
```
umount /dev/mapper/vgdataX-lvdataX
```

### Remove the disk from the device mapper
```
dmsetup remove /dev/vgdataX/lvdataX
```

### Mark the disk as offline
```
megacli -pdoffline -physdrv[E:S] -a0
```

### Mark the drive as missing
```
megacli -pdmarkmissing -physdrv[E:S] -a0
```

### Prepare the device for removal
```
megacli -PdPrpRmv -PhysDrv[E:S] -a0
```

### Have SL replace the disk during their next maintenance window
<wait patiently>

### Clear the new disk
Some combo of the following commands:
```
megacli -PDClear -Start -PhysDrv [E:S] -a0
megacli -PDClear -ShowProg -PhysDrv [E:S] -a0
# wait for clear to finish, but if you need to shortcut:
  megacli -PDClear -Stop -PhysDrv [E:S] -a0
megacli -CfgForeign -Scan -a0
```

### Create new Virtual Disk and replace the missing drive
Some combo of the following commands:
```
# Create a new RAID0 using the disk in Enclosure E, Slot S.
megacli -CfgLdAdd -r0[E:S] -a0
# If the virtual disk doesn't initiate a rebuild automatically, the following command may be needed:
megacli -PdReplaceMissing -PhysDrv[E:S] -Array0 -row0 -a0
megacli -PDMakeGood -PhysDrv [E:S] -a0
megacli -PDOnline -PhysDrv [E:S] -a0
```

### Repartition disk and remount using flotsam (BOMv2 ELK Hosts ONLY)
Use Z from above:
```
ursula ../sitecontroller-envs/remote-dc01 playbooks/bootstrap.yml --tags purge_disks -e '{ "disk_list": [ "/dev/sdZ1","sdZ"] }' --limit elk07
```

### Recreate the LVM disks and remount the disk (BOMv2 ELK Hosts ONLY)
This also starts elasticsearch and creates any missing directories in the new LVM disk.

**NOTE: This must be run against all ELK hosts in the cluster or the generated Elasticsearch config is wrong.**
```
ursula ../sitecontroller-envs/remote-dc01 site.yml -t manage-disks,elasticsearch --limit elk
```

### Start services (BOMv2 ELK Hosts ONLY)
```
service logstash stop
service kibana stop
service apache2 stop
```

### Re-Enable shard allocation (BOMv2 ELK Hosts ONLY)
```
curl -XPUT localhost:9200/_cluster/settings -d '{
    "transient" : {
        "cluster.routing.allocation.enable": "all"
    }
}'
```
