#!/bin/bash

# This starts the whole test.
# Wrapper for logging
# Get Log directory
# Get IPMI IP address
ipmitool lan print | egrep -i IP\ Address | sed 's/[^0-9,.]*//g' | tr -d "\n" > /usr/local/sbin/ipmi.txt;
mapfile -t ipmi < /usr/local/sbin/ipmi.txt;
IPMI=${ipmi[0]};
cat /root/stage2.conf | grep "SYS_DIR" > /root/flasher_config.sh;
source /root/flasher_config.sh;
RDIR="${SYS_DIR}";
U=ADMIN
P=ADMIN
DIR="/usr/local/sbin"
q="=============================="
smc="${DIR}/smctools/SMCIPMITool $IPMI $U $P";
sumtool="${DIR}/smctools/sum -i $IPMI -u $U -p $P -c"

# Drink the purple power drink
sh /usr/local/sbin/hi.sh;
echo "Wakanda Forever";
echo -e "SYSLAB Supergreen Save Mother Earth IPMI test script 3.0\n$q$q\n" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;

# Grabbing OS information
hostnamectl 2>/dev/null
if [ $? -ne 0 ]; then
	echo -e "Unable to obtain Vibran-.. System Information" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
else
	hostnamectl 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
fi

cat /etc/*-release 2>/dev/null
if [ $? -ne 0 ]; then
	echo -e "Unable to obtain Vibrani-- Release Version" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
else
	cat /etc/*-release 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
fi

# Check IPMI connection and License Key
echo -e "\nChecking for IPMI connection";
$smc ipmi ver | grep -i "Can't connect to ";
if [ $? -ne 0 ]; then
	echo -e "Connection is good.\n\nChecking for SFT-DCMS-Single license key on $IPMI" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
	$sumtool queryproductkey --no_banner --no_progress | grep -i "DCMS";
	if [ $? != 1 ]; then
		$sumtool queryproductkey --no_banner --no_progress | grep -i "Key is invalid";
		if [ $? -ne 0 ]; then
			echo -e "DCMS license key is present and valid." 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			echo -e "\n$IPMI IPMI test started on:" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			date 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			sh /usr/local/sbin/smc-temp.sh 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			echo -e "\n\nTests done, please see Logs at:\n$RDIR/$IPMI-$(date +%Y-%m-%d).log";
		else
			echo -e "There is a key, but it's invalid. Please restart and use 'cburn-r74 KDCMS' to activate key" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			echo -e "Running tests anyway. Some features might not work." 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			echo -e "\n$IPMI IPMI test started on:" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			date 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			sh /usr/local/sbin/smc-temp.sh 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
			echo -e "\n\nTests done, please see Logs at:\n$RDIR/$IPMI-$(date +%Y-%m-%d).log";
		fi
	else
		echo -e "There is no SFT-DCMS-Single license on this system." 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		echo -e "Please clear OOB key, and restart with 'cburn-r74 KDCMS' to activate DCMS license." 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		echo -e "Running tests anyway. Some features might not work." 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		echo -e "\n$IPMI IPMI test started on:" 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		date 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		sh /usr/local/sbin/smc-temp.sh 2>&1 | tee -a $RDIR/$IPMI-$(date +%Y-%m-%d).log;
		echo -e "\n\nTests done, please see Logs at:\n$RDIR/$IPMI-$(date +%Y-%m-%d).log";
	fi
else
	echo -e "No connection. Please check IPMI cables and IPMI LAN interface."
fi
