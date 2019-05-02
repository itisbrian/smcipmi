IPMI Test for Cburn
Version: 1.2.1
Build Date 2018-10-18

HOW TO RUN
1. Use AUTOPXE or ONOFF Tracker
2. TestServer 1 RC=http://172.16.94.33.101/ipmi/ipmitest.sh
3. TestServer 2 RC=http://172.16.94.33.102/ipmi/ipmitest.sh
4. Brian Server cburn DIR=/sysv/YourDirectory RC=http://172.16.94.33/ipmi/ipmitest.sh or
5. Wakanda Server cburn DIR=/sysv/YourDirectory RC=http://172.16.113.224/ipmi/ipmitest.sh
6. When tests are done, check cburn/sysv/YourDirectory for logs

Changelog
Updated 1.2.2
Add in OS info at the top

Updated in 1.2.1
Fixed Fanmode detection error when system supports PUE2
Minor edit to chassis intrusion reset log

Updated in 1.2
Added in SUM Key checking, will let you know if there is key or not, and if it's valid
Added in connection checking, make sure IPMI connection works
Run test even if no key, some tests will work
Added in NTP checking
Added in Chassis Intrusion checking/clearing

Updated in 1.1
Steven added NM power as separate script
