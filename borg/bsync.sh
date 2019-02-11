#!/bin/sh


sync
qvm-kill srv-backup
sync
lvremove -f bulk/backupsnap
sync
lvcreate -s -ay -kn -n backupsnap /dev/mapper/bulk-backupthin
sync
QD=`qvm-block | awk '/bulk-backupsnap/{print$1}'`
while [ "x$QD" = "x" ]; do 
	sleep 1
	QD=`qvm-block | awk '/bulk-backupsnap/{print$1}'`
done
echo QD $QD

qvm-start srv-backup
qvm-block a srv-backup $QD
qvm-run -p srv-backup /home/user/hdsync.sh

qvm-shutdown --wait srv-backup
sync
lvremove -f bulk/backupsnap
sync



