#!/bin/bash
#
#REMOTE IPMI ONOFF
#v1.0
#By Brian
#
#read -p "Enter IP: " ip
#read -p "Enter User name: " user 
#read -p "Enter Password: " pw

ip=$1
user=$2
pw=$3
log=$4

usage ()
{
	echo "Usage : ./onoff.sh <ip> <username> <password> <log123.txt>"
	exit
}


if [ "$#" -ne 4 ]
then
    usage
fi

echo "Remote IPMI ONOFF Log" > $log

n=0
while true;
do
status="$(ipmitool -H $ip -U $user -P $pw chassis power status | awk '{print $4}')"
  echo "${status}"
     if [ "$status" = "off" ]
	then
	   echo "Powering on System :" | tee -a $log
	   ipmitool -H $ip -U $user -P $pw chassis power on 
	   sleep 150
        else
	   echo "Powering off System" | tee -a $log
	   ipmitool -H $ip -U $user -P $pw chassis power off
	   sleep 30
	   n=$((n+1))
	   echo "--------------------------------------------------" | tee -a $log
	   echo -e "$( date '+%Y/%m/%d %H:%M:%S' ) cycle # $n" | tee -a $log
fi	
done
