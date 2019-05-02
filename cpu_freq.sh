#!/bin/bash

#######et Variables ########
TIMEOUT="30s"
LOGFILE=/usr/local/sbin/turbostat.log
CFILE=cpu_freq.log
CHECK=0
TOTAL=0

####### Run turbostat for $TIMEOUT #########
timeout $TIMEOUT turbostat -S | tee "$LOGFILE" &>/dev/null

####### Take out column 3 which contains cpu freq data and store into another log ########
awk '{ print $3 }' "$LOGFILE" | tee "$CFILE" &>/dev/null

####### Allow log files to be written #########
sleep 2

####### Read cpu freq log to take out all numerical values and store into an array and get its average number ########
RE='^[0-9]+$'
while read line; do
  if  [[ "$line" =~ $RE ]]; then
    if [ "$line" == "Bzy_MHz" ] || [ -z "$line" ]; then
      :
    else
      TOTAL=$(( TOTAL + line ))
      CHECK=$(( CHECK + 1 ))
    fi

  else
    :
  fi
done < $CFILE

####### output the average reading ##########
AVG=$(( TOTAL / CHECK ))
echo "Average CPU frequency is: $AVG MHz"


