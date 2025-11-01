#!/usr/bin/env python

import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import xmltodict, json
import os
import argparse
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Palo Alto Firewall VPN Status Check - v1.1 (Python 3 Edition)
# Tristan Self 23/10/2025
# The script uses the Palo Alto Firewall API to report on the status of IPSec VPN tunnels. You first need to obtain an API Token which is passed to the script at runtime.
# You'll need to find the name of the VPN Tunnel, because the script needs to use this to determine the "Tunnel-ID" to find the status of the tunnel.
# The plugin has been written to be used with NagiosXI, however it may be able to be used by other software for monitoring purposes.

def main():

    # Initialise variable(s)
    checkOutputStatus = 0

    # Parse the arguments passed from the command line.
    parser = argparse.ArgumentParser()
    parser.add_argument('-e','--endpointurl',help='Endpoint URL (e.g. https://firewallname.domain.com/api)',required=True)
    parser.add_argument('-a','--apitoken',help='API Token',required=True)
    parser.add_argument('-t','--tunnelname',help='Tunnel Name',required=True)
    
    # Assign each arguments to the relevant variables.
    arguments = vars(parser.parse_args())
    endpointURL = arguments['endpointurl']
    apiToken = arguments['apitoken']
    tunnelName = arguments['tunnelname']
    APITokenDict = {'X-PAN-KEY':apiToken}
    fullURL = f"{endpointURL}/?type=op&cmd=<show><running><tunnel><flow><all></all></flow></tunnel></running></show>"

    # Connect to API and retrieve results.
    try:
        # Retrieve the output
        rawOutput = requests.post(fullURL, headers = APITokenDict, verify=False)
        # Convert to a dictionary
        o = xmltodict.parse(rawOutput.content)
    except:
        # Report the error back to the user/calling program
        checkOutputStatus = 3
        print(f"CRITICAL - Failed to retrieve status from Firewall!")
        sys.exit(checkOutputStatus)

    # Iterate over the result to find tunnel name as per the argument entered
    for x in o["response"]["result"]["IPSec"]["entry"]:
        # Find matching tunnel name.
        if x["name"] == tunnelName:
            # Assign variables values for use in the verification of status and the output
            tunnelName = x["name"]
            tunnelInfName = x["inner-if"]
            tunnelPeerIP = x["peerip"]
            tunnelState = x["state"]
        
            # Determine tunnel status and report back result, UP or DOWN (OK or Critical)
            if (tunnelState == "active"):
                checkOutputStatus = 0
                print(f"OK - IPSec VPN UP - {tunnelName} {tunnelInfName} {tunnelPeerIP}")
                sys.exit(checkOutputStatus)
            else:
                checkOutputStatus = 2
                print(f"CRITICAL - IPSec VPN DOWN - {tunnelName} {tunnelInfName} {tunnelPeerIP}")
                sys.exit(checkOutputStatus)
    
    # After loop if tunnel name not found, return Unknown status
    checkOutputStatus = 3
    print(f"CRITICAL - Tunnel name not found!")
    sys.exit(checkOutputStatus)
    
# Collect and report the status
if __name__ == "__main__":
    main()