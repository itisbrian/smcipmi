#!/bin/bash

# sum body once told me the world is gonna roll me
# I ain't the sharpest sumtool in the shed
# define global variables
U=ADMIN
P=ADMIN
DIR="/usr/local/sbin"
# Get IPMI IP address on this system
ipmitool lan print | egrep -i IP\ Address | sed 's/[^0-9,.]*//g' | tr -d "\n" > ${DIR}/ipmi.txt;
mapfile -t ipmi < ${DIR}/ipmi.txt;
q="==============================";
smc="${DIR}/smctools/SMCIPMITool ${ipmi[0]} $U $P";
sumtool="${DIR}/smctools/sum -i ${ipmi[0]} -u $U -p $P -c";

# Use SUM to create backup of BMC config
echo -e "Backing up BMC config to ${DIR}/bmccfg.txt";
$sumtool GetBmcCfg --no_banner --file ${DIR}/bmccfg.txt &> /dev/null;

# Basic testing for SUM functions
: <<'END'
END
echo -e "\n$q$q\nSUM tool testing\n"
mapfile -t sumcmd < ${DIR}/sum_commands.txt;
for i in "${sumcmd[@]}"; do
	echo -e "\n$q$q\nRunning '$i' command\n$q$q\n";
	$sumtool $i --no_banner --no_progress;
done
echo -e "\n";

# Section for DMI info modifying and restoring
echo -e "Showing Current DMI Info";
$sumtool GetDmiInfo --no_banner --no_progress;
echo -e "Creates backup of DMI info into ${DIR}/dmi.txt";
$sumtool GetDmiInfo --no_banner --no_progress --file ${DIR}/dmi.txt;
cp ${DIR}/dmi.txt ${DIR}/dmi.backup;
echo -e "Start modifying DMI info in ${DIR}/dmi.txt";
$sumtool EditDmiInfo --no_banner --no_progress --file ${DIR}/dmi.txt --shn SYMF --value "Wakanda";
echo -e "Apply changes to DMI with ${DIR}/dmi.txt";
$sumtool ChangeDmiInfo --no_banner --no_progress --file ${DIR}/dmi.txt;

# Problem with this script, need to reboot server to see effect.

# Use SUM to restore BMC to default config
echo -e "Restoring BMC config from ${DIR}/bmccfg.txt";
$sumtool ChangeBmcCfg --no_banner --file ${DIR}/bmccfg.txt &> /dev/null;

# Clean up
rm -f {$DIR}/dmi.txt;
rm -f {$DIR}/bmccfg.txt;
rm -f {$DIR}/dmi.backup;
