#!/bin/bash

# define global variables
U=ADMIN
P=ADMIN
DIR="/usr/local/sbin"
# Get IPMI IP address on this system
# ipmitool lan print | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sed 's/[^0-9,.]*//g' > ${DIR}/ipmi.txt
ipmitool lan print | egrep -i IP\ Address | sed 's/[^0-9,.]*//g' | tr -d "\n" > ${DIR}/ipmi.txt;
mapfile -t ipmi < ${DIR}/ipmi.txt;
q="=============================="
smc="${DIR}/smctools/SMCIPMITool ${ipmi[0]} $U $P";
sumtool="${DIR}/smctools/sum -i ${ipmi[0]} -u $U -p $P -c"
: <<'END'
END
# Use SUM to create backup of BMC config
: <<'END'
echo -e "Backing up BMC config to ${DIR}/smctools/bmccfg.txt";
$sumtool getbmccfg --file ${DIR}/smctools/bmccfg.txt &> /dev/null;
END
# SUM has problems on X11, causes BMC lan to hang when backing up

# Use SMCIPMITool to create backup instead
: <<'END'
echo -e "Creating backup bin/text to ${DIR}/";
$smc ipmi oem backupcfg ${DIR}/backup.bin;
$smc ipmi oem getcfg ${DIR}/backup.txt;
END
# Nevermind, SMCIPMITool backup only saves Network settings
: <<'END'
END
# Basic testing SMCIMPITool functions
mapfile -t command < ${DIR}/smcipmitool_commands.txt;
for i in "${command[@]}"; do
	echo -e "\n$q$q\nRunning '$i' command\n$q$q\n";
	$smc $i;
done
	echo -e "\n";

# Basic testing for SUM functions
# sh ${DIR}/sumtest.sh

# Test Clear Chassis intrusion command
# Assumes Chassis intrusion hasn't been cleared yet
echo -e "\n$q$q\nChassis Intrusion clearing test.\n$q$q\n";
echo -e "Grabbing SEL and Sensor for Chassis status";
$smc sel list | grep -i chassis;
$smc ipmi sensor | grep -i chassis;
echo -e "\n\nClearing Chassis intrusion with SMCIPMITool";
$smc ipmi oem clrint;
sleep 20;
echo -e "Showing SEL and Sensor after Clear Intrusion\n";
$smc sel list | grep -i chassis;
$smc ipmi sensor | grep -i chassis;
echo -e "Please compare SEL and Sensor before and after Clear Intrusion"

# Test SMCIPMITool user creation and deletion
echo -e "\n$q$q\nUser Add/Delete, and Privilege Testing\n$q$q\n";
$smc user list;
for i in {3..10}; do
	echo -e "Adding User ID: $i";
	$smc user add $i user$i password$i 4;
	if [[ $i != 10 ]]; then
		echo -e "Testing User ID: $i";
		$smc user test user$i password$i;
		echo -e "Change User ID: $i access level to Operator";
		$smc user level $i 3;
		sleep 1;
		echo -e "Test User ID: $i";
		$smc user test user$i password$i;
	elif [[ $i == 10 ]]; then
		$smc user list;
	fi
done
echo -e "Done testing users, deleting users now.";
for i in {3..10}; do
	$smc user delete $i &> /dev/null;
done
	$smc user list;

# Test SMCIPMITool FRU read / write, restore from cfg file
echo -e "\n$q$q\nFRU Testing\n$q$q\nShowing default FRU";
$smc ipmi fru;
echo -e "Creating fru.backup";
$smc ipmi frubackup ${DIR}/fru.backup;
echo -e "\nCustomizing FRU"
mapfile -t frucmd < ${DIR}/fru_commands.txt;
for i in "${frucmd[@]}"; do
	echo -e "Writing FRU '$i'";
	$smc ipmi fruw $i &> /dev/null;
done
echo -e "Finished modifying FRU\n\nDisplaying changed FRU\n$q$q";
$smc ipmi fru;
echo -e "Restoring default FRU from backup\n\nDisplaying default FRU\n$q$q";
$smc ipmi frurestore ${DIR}/fru.backup;
$smc ipmi fru;
rm -f ${DIR}/fru.backup;

# Test Fan Modes and Record speed for each mode
echo -e "\n$q$q\nFan Modes Testing\n$q$q\nChecking for supported fan modes";
$smc ipmi fan | sed 's/[^0-9,.][PUE1,PUE2]*//g' | sed '/^\s*$/d' > ${DIR}/supportedfanmodes.txt;
mapfile -t fanmodes < ${DIR}/supportedfanmodes.txt;
for i in "${fanmodes[@]}"; do
	echo -e "\nTesting Fan Mode '$i'"
	$smc ipmi fan $i &> /dev/null;
	sleep 45;
	$smc ipmi fan | grep Current;
	$smc ipmi sensor | grep FAN;
done
rm -f ${DIR}/supportedfanmodes.txt;

#NM power policy testing
${DIR}/nm_power.sh;

# NTP Testing
echo -e "\n$q$q\nTesting SMCIPMITool NTP commands\n$q$q\nGetting Current NTP settings:";
$smc ipmi oem x10cfg ntp list;

echo -e "\nEnabling NTP";
$smc ipmi oem x10cfg ntp state enable;

echo -e "\nSetting Up NTP Servers";
$smc ipmi oem x10cfg ntp primary time.nist.gov &> /dev/null;
$smc ipmi oem x10cfg ntp primary;
$smc ipmi oem x10cfg ntp secondary time-a-wwv.nist.gov &> /dev/null;
$smc ipmi oem x10cfg ntp secondary;
echo -e "Enabling Daylight Saving Time";
$smc ipmi oem x10cfg ntp daylight yes;
echo -e "Setting Timezone +7 (PST)";
$smc ipmi oem x10cfg ntp timezone +0700 enable &> /dev/null;

echo -e "\nShowing New NTP settings:";
$smc ipmi oem x10cfg ntp list;

echo -e "\nNTP tests done. Cleaning up\nDefault NTP settings:";
$smc ipmi oem x10cfg ntp primary localhost &> /dev/null;
$smc ipmi oem x10cfg ntp secondary 127.0.0.1 &> /dev/null;
$smc ipmi oem x10cfg ntp timezone +0000 &> /dev/null;
$smc ipmi oem x10cfg ntp daylight no &> /dev/null;
$smc ipmi oem x10cfg ntp state disable enable &> /dev/null;
$smc ipmi oem x10cfg ntp list;

# Use SUM to restore BMC to default config
#echo -e "Restoring BMC config from ${DIR}/smctools/bmccfg.txt";
#$sumtool changebmccfg --file ${DIR}/smctools/bmccfg.txt
#$sumtool GetDmiInfo --file ${DIR}/dmi.txt

# Use SMCIPMITool to restore from backup
: <<'END'
echo -e "Restoring from backup bin/text in ${DIR}/";
$smc ipmi oem restorecfg ${DIR}/backup.bin;
sleep 60;
$smc ipmi oem setcfg ${DIR}/backup.txt;
sleep 60;
rm -f ${DIR}/backup.bin;
rm -f ${DIR}/backup.txt;
END
# It takes 60 seconds after restore cfg, lan goes down
