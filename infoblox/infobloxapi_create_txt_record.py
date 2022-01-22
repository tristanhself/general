#!/usr/bin/env python
from infoblox_client import objects
from infoblox_client import connector
import urllib3
urllib3.disable_warnings()
import argparse

#############################################################################################
# Documentation and Example
#############################################################################################

# infobloxapi_create_txt_record.py - Create/Update TXT Record for Domain
#
# https://github.com/infobloxopen/infoblox-client

# An example is given below to create a DMARC record on a domain with an attached comment.
#
# ./infobloxapi_create_txt_record.py -e infoblox1.domain.com -u <username> -p <password> -c True -x True -v external -n "_dmarc.mydomain.com" -t "v=DMARC1;p=none;fo=1;rua=mailto:dmarc_rua@dmarccheck.com;ruf=mailto:dmarc_ruf@dmarccheck.com" -o "Email DMARC record, detailing the email domain security posture and reporting information."
#
# Another example to create an SPF record on a domain with an attached comment.
#
# ./infobloxapi_create_txt_record.py -e infoblox1.domain.com -u <username> -p <password> -c True -x True -v external -n "mydomain.com" -t "\"v=spf1 -all\"" -o "Email SPF record, detailing the authorised SMTP sender IP addresses for the domain."
# Note: the text record needs to include a preceeding slash and trailing slash to ensure the item is taken as a text string with the space, or the record will appear invalid.

#############################################################################################
# Argument Collection
#############################################################################################

# Parse the arguments passed from the command line.
parser = argparse.ArgumentParser()
parser.add_argument('-e','--endpointurl',help='ECS Cluster Endpoint URL (e.g. infoblox1.domain.com)',required=True)
parser.add_argument('-u','--username',help='Username',required=True)
parser.add_argument('-p','--password',help='Password',required=True)
parser.add_argument('-c','--checkifexists',help='Check if record exists already: True or False',required=True)
parser.add_argument('-x','--updateifexists',help='Update an existing record if it exists already: True or False',required=True)
parser.add_argument('-v','--view',help='View (External or Internal)',required=True)
parser.add_argument('-n','--recordname',help='Domain or subdomain of TXT Record, e.g. _dmarc.domain.com',required=True)
parser.add_argument('-t','--recordtext',help='Text string for the record, e.g. your DMARC or SPF record etc.',required=True)
parser.add_argument('-o','--recordcomment',help='A description string for the record',required=True)

# Assign each arguments to the relevant variables.
arguments = vars(parser.parse_args())
EndpointURL = arguments['endpointurl']
APIUsername = arguments['username']
APIPassword = arguments['password']
CheckIfExists = arguments['checkifexists']
UpdateIfExists = arguments['updateifexists']
View = arguments['view']
RecordName = arguments['recordname']
RecordText = arguments['recordtext']
RecordComment = arguments['recordcomment']

opts = {'host': EndpointURL, 'username': APIUsername, 'password': APIPassword}
conn = connector.Connector(opts)

try:
        new_txtrecord = objects.TXTRecord.create(conn,check_if_exists=CheckIfExists,update_if_exists=UpdateIfExists,view=View,name=RecordName,text=RecordText,comment=RecordComment)
        # print (new_txtrecord)
        print "\033[0;37;40m{} - \033[1;32;40mOK\033[0;37;40m".format(RecordName)
except:
        print "\033[0;37;40m{} - \033[1;31;40mFAIL!\033[0;37;40m".format(RecordName)
