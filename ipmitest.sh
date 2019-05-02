#!/bin/bash
# Author: Long Nguyen
# Copied the start.sh from brian, modified it so it will launch ipmitest.sh
# This script replaces tty2 (alt+f2) with a console 
# ipmitest.sh will launch getty-wakanda@service, the service will launch
# logger.sh. Logger.sh is basically a wrapper for the main program
# smc-temp.sh. The logger provides the log for the whole test, you can find the log in cburn directory
# smc-temp.sh contains all the tests. packy.tar is the tools package required
# for smc-temp.sh tests.
# 
# Requirements are:
# cburn, AutoPXE or OnOff Tracker
IP=172.16.94.101
DIR="/usr/local/sbin";

# Brian wanted to add this bit to ipmitest.sh for logging
echo " " 
echo "Modifying bashrc." | tee /dev/tty0

echo "source /root/stage2.conf" >> /root/.bash_profile
echo 'if test -t 0; then' >> /root/.bash_profile
echo 'script -f "${SYS_DIR}"/tty"${XDG_VTNR}".txt' >> /root/.bash_profile
echo 'exit' >> /root/.bash_profile
echo "fi" >> /root/.bash_profile

systemctl restart getty-auto-root@tty10
systemctl restart getty-auto-root@tty11
systemctl restart getty-auto-root@tty12

echo -e "\e[32mLogger Started.\e[0m" | tee /dev/tty0
# end of the logging portion


echo -e "\nRetrieving test packages from ${IP}.\nMake sure it is westworld.bnet!" |tee -a /dev/tty0;
wget "http://${IP}/ipmi/getty-wakanda@.service" -O "/lib/systemd/system/getty-wakanda@.service" &> /dev/null;
if [ $? -ne 0 ]; then
	echo -e "Failed to acquire getty service for ipmi tests.\nNo Vibranium here." | tee /dev/tty0;
	return 1;
	exit 1;
fi
echo -e "Wakanda Service installed.\nWelcome to Wakanda." | tee /dev/tty0;
########################################################################################################################
/usr/bin/systemctl daemon-reload;
if [ $? -ne 0 ]; then
	echo -e "Failed to reload systemd." | tee /dev/tty0;
	return 2;
#	exit 2
fi
echo -e "Systemd reload finished." | tee /dev/tty0;
########################################################################################################################
mkdir ${DIR}/smctools/;
wget "http://${IP}/ipmi/packy.tar" -O "${DIR}/smctools/packy.tar" &> /dev/null;
if [ $? -ne 0 ]; then
	echo -e "Failed to get the tools package.\nMr. Stark... I don't feel so good." | tee /dev/tty0;
	return 1;
#	exit 1;
fi
echo -e "SMCI tools installed." | tee /dev/tty0;

########################################################################################################################
wget "http://${IP}/ipmi/nm_power.sh" -O "${DIR}/nm_power.sh" &>/dev/null;
wget "http://${IP}/ipmi/smc-temp.sh" -O "${DIR}/smc-temp.sh" &> /dev/null;
wget "http://${IP}/ipmi/logger.sh" -O "${DIR}/logger.sh" &> /dev/null;
wget "http://${IP}/ipmi/hi.sh" -O "${DIR}/hi.sh" &> /dev/null;
wget "http://${IP}/ipmi/fancmd.txt" -O "${DIR}/fancmd.txt" &> /dev/null;
wget "http://${IP}/ipmi/smcipmitool_commands.txt" -O "${DIR}/smcipmitool_commands.txt" &> /dev/null;
wget "http://${IP}/ipmi/sum_commands.txt" -O "${DIR}/sum_commands.txt" &> /dev/null;
wget "http://${IP}/ipmi/fru_commands.txt" -O "${DIR}/fru_commands.txt" &> /dev/null;
wget "http://${IP}/ipmi/cpu_freq.sh" -O "${DIR}/cpu_freq.sh" &> /dev/null;
wget "http://${IP}/ipmi/sumtest.sh" -O "${DIR}/sumtest.sh" &> /dev/null;
if [ $? -ne 0 ]; then
	echo -e "Failed to get scripts." | tee /dev/tty0;
	return 1;
#	exit 1;
fi
chmod +x ${DIR}/*.sh;
echo -e "SMCIPMITool scripts installed." | tee /dev/tty0;

########################################################################################################################
tar -xf ${DIR}/smctools/packy.tar -C ${DIR}/smctools/ --strip 1 &> /dev/null;
chmod +x ${DIR}/smctools/SMCIPMITool;
chmod +x ${DIR}/smctools/sum;
/usr/bin/systemctl stop getty-auto-cburn@tty2.service;
/usr/bin/systemctl stop getty-auto-root@tty2.service;
/usr/bin/systemctl stop getty@tty2.service;
echo -e "\n\e[32m\e[5mStarting Scripts. Press Alt+F2 to view Progress on tty2.\e[0m\n" | tee -a /dev/tty0;
/usr/bin/systemctl start getty-wakanda@tty2.service;

#echo "Waiting for completion of FIO" | tee -a /dev/tty0
#sleep 86400
#echo "FIO Test Finished" | tee -a /dev/tty0
