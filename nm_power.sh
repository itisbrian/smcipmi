#define variables
U=ADMIN
P=ADMIN
DIR="/usr/local/sbin"
ipmitool lan print | egrep -i IP\ Address | sed 's/[^0-9,.]*//g' | tr -d "\n" > ${DIR}/ipmi.txt;
mapfile -t ipmi < ${DIR}/ipmi.txt;
q="=============================="
smc="${DIR}/smctools/SMCIPMITool ${ipmi[0]} $U $P";
sumtool="${DIR}/smctools/sum -i ${ipmi[0]} -u $U -p $P -c"
nm_detect=`$smc nm detect`;

if [ "$nm_detect" != "This device supports Node Manager" ];then
	echo -e "$q$q\nThis system doesn't support NM, skip NM test\n$q$q";
else
	# sample idle power
	power=0
	$smc nm delpolicy 1 &>/dev/null;
	sleep 10;
	echo -e "$q$q\nNM policy testing start\n$q$q";
	for k in {1..10} ;do
		p=`$smc nm20 oemgetpower | cut -d " " -f 1 `;
		echo -e "Sampling power(OS idle): $p W";
		sleep 1;
		let "power+=$p";
		let "power1=$((power/10))"
	done
	echo -e "$q$q\nAverage idle power in Cburn is: $power1 W";
	echo -e "Measuring CPU frequency, please wait";
	${DIR}/cpu_freq.sh;
	# stress cpu and sample power
	echo -e "$q$q\nTesting power policy using node manager\n$q$q\nstress up CPUs on your system";
	echo -e "Waiting 20s to stress\n$q$q";
	/root/x86-sat/stress-ng --cpu 0 -q &>/dev/null &
	sleep 20;
	power=0
	for k in {1..30} ;do
		p=`$smc nm20 oemgetpower | cut -d " " -f 1 `;
		echo -e "Sampling power(under CPU stress): $p W";
		sleep 1;
		let  "power+=$p";
	done
	let "power2=$((power/30))";
	echo -e "$q$q\nAverage power under stress is: $power2 W";
	echo -e "Measuring CPU frequency, please wait";
	${DIR}/cpu_freq.sh;
	# apply power policy and sample power
	echo -e "$q$q\nApply power policy #12 to cap CPU power";
	echo -e "Setting power limit to $((power1+((power2-power1)*8/10))) W";
	$smc nm addpolicy 12 $((power1+((power2-power1)*8/10))) 6000 10 &>/dev/null;
	$smc nm scanpolicy;
	echo -e "$q$q";
	sleep 20;
	power=0
	for k in {1..30} ;do
		p=`$smc nm20 oemgetpower |cut -d " " -f 1 `;
		echo -e "Sampling power (policy enable): $p W";
		sleep 1;
		let "power+=$p";
	done
	let "power3=$(($power/30))";
	echo -e "$q$q\nAverage power with policy enable is: $power3 W";
	echo -e "Measuring CPU frequency, please wait";
	${DIR}/cpu_freq.sh;
	# show nm power test reault
	echo -e "$q$q\nPlease check power reading in logs to check if power policy works\n$q$q\n";
	echo -e "Clear existing policy 12 and nm power policy test is finished";
	$smc nm delpolicy 12 >/dev/null;
	pin=`pgrep stress-ng`;
	echo -e "\nStress test will be killed automatically";
	kill $pin
	echo -e " "
fi
