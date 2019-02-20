#!/bin/sh


TMP_VM="disp-tpl-$RANDOM"
#TMP_VM=disp-tpl-28765
#TMP_DIR="/tmp/template"
TMP_DIR="/home/user/qubes-templates"
TMP_INC="/home/user/QubesIncoming/dom0"
TMP_YUM="/etc/yum.repos.d"
TMP_LABEL=orange
#echo TMP_VM: $TMP_VM
#echo TMP_DIR: $TMP_DIR

echo Creating TMP_VM "'$TMP_VM'" ...
qvm-create -l black $TMP_VM
qvm-volume resize $TMP_VM:private 20GiB
qvm-start $TMP_VM
qvm-run -p $TMP_VM "mkdir -p $TMP_DIR"


TARGET=$1
echo -n "Processing '$TARGET' ... "
if [ -e "$TARGET" ] ; then
	echo as local file ...
	qvm-copy-to-vm $TMP_VM $TARGET
	PKG_FILE=`basename $TARGET`
	qvm-run -p $TMP_VM "mv $TMP_INC/$PKG_FILE $TMP_DIR/"
elif grep "^[-a-z0-9]*:" <<< $TARGET ; then
	echo as remote file ...
	SRC_VM=`cut -d: -f1 <<< $TARGET`
	SRC_FILE=`cut -d: -f2 <<< $TARGET`
	PKG_FILE=`basename $SRC_FILE`
	qvm-run -p $SRC_VM "cat $SRC_FILE" |
	qvm-run -p $TMP_VM "cd $TMP_DIR && cat > $PKG_FILE"
else
	echo as repo file ...
	qvm-copy-to-vm $TMP_VM /etc/yum.repos.d/qubes-templates.repo 
	qvm-run -p -u root $TMP_VM "rm $TMP_YUM/* && mv $TMP_INC/qubes-templates.repo $TMP_YUM/"
		# && sed -ie 's/\\\$releasever/4.0/g' /etc/yum.repos.d/qubes-templates.repo"
	qvm-run -p $TMP_VM "cd $TMP_DIR && dnf download -y --releasever=4.0 $TARGET"
	PKG_FILE=`qvm-run -p $TMP_VM "cd $TMP_DIR && ls -td $TARGET*" | head -1`
fi
#echo PKG_FILE: $PKG_FILE
if [ "x$PKG_FILE" == "x" ] ; then
	exit 1
fi

# TODO check/verify rpm

TPL_VMNAME=`sed -e 's/^qubes-template-//;s/^\(\([a-z0-9]\+-\)\+\).*-\(20[0-9][0-9][0-9][0-9][0-9][0-9]\).*$/\1\3/' <<< $PKG_FILE`
TPL_NAME=`sed -e 's/-[0-9]\+$//' <<< $TPL_VMNAME`
TPL_LABEL=orange
echo TPL_NAME: $TPL_NAME
echo TPL_VMNAME: $TPL_VMNAME

# unpack RPM
echo "Unpacking '$PKG_FILE' in $TMP_VM ..."
qvm-run -p $TMP_VM "cd $TMP_DIR && rpm2cpio $PKG_FILE | cpio -idm"

PKG_DIR=`qvm-run -p $TMP_VM "cd $TMP_DIR && ls -td var/lib/qubes/vm-templates/* | head -1"`
echo PKG_DIR: $PKG_DIR
PKG_NAME=`basename $PKG_DIR`
if [ "x$TPL_NAME" != "x$PKG_NAME" ] ; then
	echo WARN: name mismatch $TPL_NAME ne $PKG_NAME
fi

TPL_SUFF=0
TPL_OVMNAME=$TPL_VMNAME
TPL_VMNAME=`
( echo $TPL_VMNAME
while qvm-ls $TPL_VMNAME &> /dev/null; do
	let TPL_SUFF=$TPL_SUFF+1
	TPL_VMNAME="$TPL_OVMNAME-$TPL_SUFF"
	echo $TPL_VMNAME
done ) | tail -1
`
#echo TPL_VMNAME: $TPL_VMNAME
echo Creating $TPL_VMNAME ...
qvm-create --label $TPL_LABEL --class TemplateVM $TPL_VMNAME || exit 1

echo "Setting $TPL_VMNAME properties ..."
# TODO proper shell escape protection
if [ -e /root/tplspec.$PKG_NAME ] ; then 
	cat /root/tplspec.$PKG_NAME 
else
	qvm-run -p $TMP_VM "cd $TMP_DIR/$PKG_DIR && cat tplspec"
fi |
grep -E "^(prop|feat) [-a-z_]* [a-z0-9A-Z_()/.]*$" | 
while read t k v ; do 
	echo "SPEC '$t' '$k' '$v'" 
	if [ "x$t" == "xprop" ] ; then
	       qvm-prefs $TPL_VMNAME $k "$v"
	elif [ "x$t" == "xfeat" ] ; then
	       qvm-features $TPL_VMNAME $k "$v"
	else
		echo BAD TAG $t
	fi
done

TPL_ROOT=`qvm-volume i $TPL_VMNAME:root | awk '/^vid/{print "/dev/"$2}'`
if [ "x$TPL_ROOT" == "x" -o ! -e $TPL_ROOT ] ; then
	echo ERR: root $TPL_ROOT not found
	exit 1
fi

echo Copying root.img to $TPL_ROOT ...
qvm-run -p $TMP_VM "cd $TMP_DIR/$PKG_DIR && cat root.img.part.* | tar xOf - root.img" | 
dd of=$TPL_ROOT conv=sparse

#exit 0

echo Removing $TMP_VM ...
qvm-kill $TMP_VM
qvm-remove -f $TMP_VM



