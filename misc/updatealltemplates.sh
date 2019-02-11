

qvm-prefs sys-firewall maxmem 500; 

TPL=`qvm-ls | awk '/TemplateVM/{print$1}' | grep -Ev "^mirage"`
for t in $TPL; do 
	echo $t;
	qvm-prefs $t maxmem 1000; 
	( qvm-run -u root --service $t qubes.InstallUpdatesGUI &
  	qvm-run -u root -p $t "fstrim -av" ) &
done


