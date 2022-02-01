#!/bin/bash

# Dell ECS Hardware Monitoring Script - V1.0
# Version 1.0 - 6/01/2022

# The script should be set to be executable and run using "admin" and then run from a Cron job at whatever interval as required, perhaps once an hour, this
# would then send back the result to NagiosXI for visibility to System Administrators.

# Set Variables for the script.
NAGIOSURL="https://nagios.domain.com/nrdp/"
NAGIOSTOKEN="<keyhere>"
PSERRORCOUNT=0
FANERRORCOUNT=0
NICERRORCOUNT=0

# Get the node name and strip off "pub".
ECSNODENAMERAW=${HOSTNAME%%.*}
ECSNODENAME=${ECSNODENAMERAW//pub-/}


# Get the output from iDRAC of the status and put into an array.
readarray -t my_array < <(sudo /opt/dell/srvadmin/sbin/racadm getsensorinfo)

# Get the status of the NICS into an array.
readarray -t my_array2 < <(ip addr)



# Check if the response is empty, i.e. the command to collect the data didn't work.
if [[ ! ${my_array[*]} ]]; then
        echo "CRITICAL - Unable to obtain hardware information!"
        /tmp/send_nrdp.sh -u $NAGIOSURL -t $NAGIOSTOKEN -H $ECSNODENAME -s "Node Health Status" -S 2 -o "ERROR - Unable to obtain hardware information!"
        exit 2
fi

############################### Process the output for errors and status ##########################################

for i in "${my_array[@]}"
do
        LINESTRING=$i

        # Check PSU 1
        if [[ $LINESTRING == *"PS1 Status"* ]]; then
                PS1STATUS=`echo $LINESTRING | awk '{print $3}'`
                if [ $PS1STATUS != "Present" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "PSERRORCOUNT++"
                fi
        fi

        # Check PSU 2
        if [[ $LINESTRING == *"PS2 Status"* ]]; then
                PS2STATUS=`echo $LINESTRING | awk '{print $3}'`
                if [ $PS2STATUS != "Present" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "PSERRORCOUNT++"
                fi
        fi

        # Check PS Fans
        if [[ $LINESTRING == *"System Board PS Redundancy"* ]]; then
                PSFANSTATUS=`echo $LINESTRING | awk '{print $5}'`
                #echo $SBFAN1STATUS
                if [ $PSFANSTATUS != "Full" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "FANERRORCOUNT++"
                fi
        fi

        # Check System Fans
        if [[ $LINESTRING == *"System Board Fan Redundancy"* ]]; then
                SYSFANSTATUS=`echo $LINESTRING | awk '{print $5}'`
                #echo $SBFAN1STATUS
                if [ $SYSFANSTATUS != "Full" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "FANERRORCOUNT++"
                fi
        fi

done

############################################ Network Card ########################################################

#echo $my_array2

for j in "${my_array2[@]}"
do
        LINESTRING2=$j

        # Check Private NIC 0
        if [[ $LINESTRING2 == *"pslave-0"* ]]; then
                PIVNIC0STATUS=`echo $LINESTRING2 | awk '{print $11}'`
                if [ $PIVNIC0STATUS != "UP" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "NICERRORCOUNT++"
                fi
        fi

        # Check Private NIC 1
        if [[ $LINESTRING2 == *"pslave-1"* ]]; then
                PIVNIC1STATUS=`echo $LINESTRING2 | awk '{print $11}'`
                if [ $PIVNIC1STATUS != "UP" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "NICERRORCOUNT++"
                fi
        fi

        # Check Public NIC 0
        if [[ $LINESTRING2 == *"slave-0"* ]]; then
                PUBNIC0STATUS=`echo $LINESTRING2 | awk '{print $11}'`
                if [ $PUBNIC0STATUS != "UP" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "NICERRORCOUNT++"
                fi
        fi

        # Check Public NIC 1
        if [[ $LINESTRING2 == *"slave-1"* ]]; then
                PUBNIC1STATUS=`echo $LINESTRING2 | awk '{print $11}'`
                if [ $PUBNIC1STATUS != "UP" ]; then
                        # A faulty component has been found, increment the error count by one.
                        let "NICERRORCOUNT++"
                fi
        fi

done





############################################ Output Script ########################################################

# Debug Ouput
#echo $PS1STATUS
#echo $PS2STATUS
#echo $PSFANSTATUS
#echo $SYSFANSTATUS
#echo $PIVNIC0STATUS
#echo $PIVNIC1STATUS
#echo $PUBNIC0STATUS
#echo $PUBNIC1STATUS
#echo $PSERRORCOUNT
#echo $FANERRORCOUNT
#echo $NICERRORCOUNT


if [ $PSERRORCOUNT == 0 ] && [ $FANERRORCOUNT == 0 ] && [ $NICERRORCOUNT == 0 ]; then
        echo "OK - Node Health Status: HEALTHY - PSU Faults:" $PSERRORCOUNT", Fan Faults:" $FANERRORCOUNT", NIC Errors:" $NICERRORCOUNT
        /tmp/send_nrdp.sh -u $NAGIOSURL -t $NAGIOSTOKEN -H $ECSNODENAME -s "Node Health Status" -S 0 -o "HEALTHY - PSU Faults: $PSERRORCOUNT, Fan Faults: $FANERRORCOUNT, NIC Errors: $NICERRORCOUNT"
else
        echo "CRITICAL - Node Health Status: DEGRADED - PSU Faults:" $PSERRORCOUNT", Fan Faults:" $FANERRORCOUNT", NIC Errors:" $NICERRORCOUNT
        /tmp/send_nrdp.sh -u $NAGIOSURL -t $NAGIOSTOKEN -H $ECSNODENAME -s "Node Health Status" -S 2 -o "DEGRADED - PSU Faults: $PSERRORCOUNT, Fan Faults: $FANERRORCOUNT, NIC Errors: $NICERRORCOUNT"
fi

