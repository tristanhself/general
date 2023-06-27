# VMware VMKPing HPE Nimble Storage iSCSI Connectivity Test Script
# Assumes you have two storage arrays, prune the below set of variables accordingly if you only have one.
# Assumes your VMware host has two VMKernel ports for iSCSI (it really should!) vmk1 and vmk2.
# Performs an iSCSI connectivity test of a "full mesh" connectivity.

N1_DISCOVERY_IP=172.30.130.33
N2_DISCOVERY_IP=172.30.130.50

N1_ISCSI_IP1=172.30.130.34
N1_ISCSI_IP2=172.30.130.35
N1_ISCSI_IP3=172.30.130.234
N1_ISCSI_IP4=172.30.130.235
N2_ISCSI_IP1=172.30.130.51
N2_ISCSI_IP2=172.30.130.52
N2_ISCSI_IP3=172.30.130.251
N2_ISCSI_IP4=172.30.130.252

TOTALRETURN_CODE=0

ping_iscsi() {
        vmkping -c 2 -d -s 1472 -W 2 -I $1 $2 > /dev/null
        RETURN_CODE=$?
        if [ $RETURN_CODE -eq 0 ]
        then
                echo $1 $2 "OK"
        else
                echo $1 $2 "FAIL!"
        fi
        TOTALRETURN_CODE=$(( $TOTALRETURN_CODE + $RETURN_CODE ))
}
echo ""
echo "Performing Storage iSCSI Connectivity Tests - DF Set, 1500 (1472) byte MTU, 2 Second Timeout"
echo ""
echo "Nimble Storage Array 01 - Discovery IP Tests"
ping_iscsi vmk1 $N1_DISCOVERY_IP
ping_iscsi vmk2 $N1_DISCOVERY_IP
echo ""
echo "Nimble Storage Array 02 - Discovery IP Tests"
ping_iscsi vmk1 $N2_DISCOVERY_IP
ping_iscsi vmk2 $N2_DISCOVERY_IP
echo ""
echo "Nimble Storage Array 01 - iSCSI Storage IP Tests"
ping_iscsi vmk1 $N1_ISCSI_IP1
ping_iscsi vmk1 $N1_ISCSI_IP2
ping_iscsi vmk1 $N1_ISCSI_IP3
ping_iscsi vmk1 $N1_ISCSI_IP4
ping_iscsi vmk2 $N1_ISCSI_IP1
ping_iscsi vmk2 $N1_ISCSI_IP2
ping_iscsi vmk2 $N1_ISCSI_IP3
ping_iscsi vmk2 $N1_ISCSI_IP4
echo ""
echo "Nimble Storage Array 02 - iSCSI Storage IP Tests"
ping_iscsi vmk1 $N2_ISCSI_IP1
ping_iscsi vmk1 $N2_ISCSI_IP2
ping_iscsi vmk1 $N2_ISCSI_IP3
ping_iscsi vmk1 $N2_ISCSI_IP4
ping_iscsi vmk2 $N2_ISCSI_IP1
ping_iscsi vmk2 $N2_ISCSI_IP2
ping_iscsi vmk2 $N2_ISCSI_IP3
ping_iscsi vmk2 $N2_ISCSI_IP4
echo ""
if [ $TOTALRETURN_CODE -eq 0 ]
then
        echo "PASS - All tests successful!"
else
        echo "FAIL - Some tests failed, please inspect to determine failures!"
fi
echo ""
