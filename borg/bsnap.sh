#!/bin/sh

declare -x BORG_PASSPHRASE="borgpw"
declare -x BORG_REPO="/backup/local"
declare -x PATH="/sbin:/bin:/usr/sbin:/usr/bin"

#FL=""
#for a in `ls /var/lib/qubes/appvms/*/private.img | 
#		cut -d/ -f6 | 
#		egrep -v "(^disp-|^mirage-|whonix|-dvm$|-agent$)"`; do  
#			#echo $a; 
#			FL="$FL /var/lib/qubes/appvms/$a/private.img"; 
#done

#export BORG_RSH=/bwrap.sh
#export BORG_REPO=foo@bar:/backup

#FL=`ls /dev/*/vm-*-private /dev/*/vm-*-private-snap | egrep -v "(^|/)vm-((disp|sys|mirage)-[^/]*|.*whonix.*|.*-dvm|.*-agent)-private"`

FLP=`ls /dev/*/vm-*-private | egrep -v "(^|/)vm-((disp|sys|mirage)-[^/]*|.*whonix.*|.*-dvm|.*-agent)-private"`
( time borg prune -v --list -P priv --keep-hourly 30 --keep-daily 30 --keep-weekly 30 --keep-monthly 30 ) &> /tmp/_bprune.priv.out
( time borg create ::priv-\{now:%Y-%m-%d-%H-%M-%S\} $FLP -x -v --progress --stats --list --read-special ) &> /tmp/_bsnap.priv.out

FLS=`ls /dev/*/vm-*-private-snap | egrep -v "(^|/)vm-((disp|sys|mirage)-[^/]*|.*whonix.*|.*-dvm|.*-agent)-private"`
( time borg prune -v --list -P snap- --keep-hourly 30 --keep-daily 30 --keep-weekly 30 --keep-monthly 30 ) &> /tmp/_bprune.snap.out
( time borg create ::snap-\{now:%Y-%m-%d-%H-%M-%S\} $FLS -x -v --progress --stats --list --read-special ) &> /tmp/_bsnap.snap.out

FLD="/"
( time borg prune -v --list -P dom0- --keep-hourly 30 --keep-daily 30 --keep-weekly 30 --keep-monthly 30 ) &> /tmp/_bprune.dom0.out
( time borg create ::dom0-\{now:%Y-%m-%d-%H-%M-%S\} $FLD -x -v --progress --stats --list ) &> /tmp/_bsnap.dom0.out

#( cd /backuptest/local && find | perl -ne 'chomp;$f=$_;$t=$f;$t=~s,^\./,/backuptest/hypermerge/,;next if -e $t;if(-d$f){mkdir $t}elsif(-f$f){link $f,$t}else{warn"WAT: $f"}')

LOCKFILE=/tmp/_rsync.lock
if [ -e $LOCKFILE ]; then 
	echo lock $LOCKFILE exists
else
	echo $$ > $LOCKFILE
#	qvm-run -a -p --user root srv-backup "while [ ! -e /backup/data ] ; do date; sleep 1; done" &&
#   	( time rsync -varWut --delete --progress -e /root/rswrap.sh /backup/local/ foo@bar:/backup/ ) &> /tmp/_rsync.out
   	time /root/bsync.sh &> /tmp/_bsync.out
	rm $LOCKFILE
fi



