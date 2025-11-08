#!/usr/bin/env python3
import argparse
import json
import sys
#from datetime import date
import datetime
from decimal import Decimal, InvalidOperation
from typing import Dict, Any, List, Optional
import xmltodict, json

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

# AWS Budget Check - v1.0 (Python 3 Edition)
# Tristan Self 05/11/2025
# The script uses the AWS API via Boto to access the AWS Budget information and report on the current budget status. There are no thresholds specified
# as part of the check script, it uses what is specified within the Budget and then alerts based on that.
# When using an Access Key and Secret Key it is strongly recommended to heavily restrict what the IAM account can do, i.e. read only to Budgets only, and
# ensure that the 

# Example Usage:
# ./check_aws_budget.py --accountid <AWS Account ID> --budgetname <Budget Name> --region <AWS Region> --accesskey <Access Key> --secretkey <Secret Key>
# 
# Example Usage with pretend values:
# ./check_aws_budget.py --accountid 1234567890 --budgetname "My Budget" --region eu-west-2 --accesskey 37gdyewgf6sdfg6ds --secretkey gf6sdfggf6sdfg6ds6ds37gdyew

def main():

    # Obtain the arguments from command line.
    parser = argparse.ArgumentParser(description="Check AWS Budget status and alert breaches.")
    parser.add_argument("--accountid", required=True, help="12-digit AWS Account ID")
    parser.add_argument("--budgetname", required=True, help="Budget name to inspect")
    parser.add_argument("--region", default="eu-west-2", help="(Unused for Budgets) default us-east-1")
    parser.add_argument("--accesskey", help="AWS_ACCESS_KEY_ID")
    parser.add_argument("--secretkey", help="AWS_SECRET_ACCESS_KEY")
    arguments = vars(parser.parse_args())

     # Assign each arguments to the relevant variables.
    accountID = arguments['accountid']
    budgetName = arguments['budgetname']
    region = arguments['region']
    accessKey = arguments['accesskey']
    secretKey = arguments['secretkey']

    # Initialise variable(s)
    checkOutputStatus = 0
    warningState = False
    criticalState = False
    exceededReport = ""

    # Generate datetime string
    dateTime = datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S")

    # Create the Session
    session = boto3.Session(
                aws_access_key_id=accessKey,
                aws_secret_access_key=secretKey,
                region_name=region
            )

    # Connect to the API and obtain the data
    try:
        client = session.client("budgets", region_name=region, config=Config(retries={"max_attempts": 10}))
        resp = client.describe_budget(AccountId=accountID, BudgetName=budgetName)
        resp2 = client.describe_notifications_for_budget(AccountId=accountID, BudgetName=budgetName)
    except:
        # Report the error back to the user/calling program
        checkOutputStatus = 3
        print(f"CRITICAL - Failed to access AWS Budgets!")
        sys.exit(checkOutputStatus)

    budgetName = resp["Budget"]["BudgetName"]
    budgetLimit = int(float(resp["Budget"]["BudgetLimit"]["Amount"]))
    actualSpend = int(float(resp["Budget"]["CalculatedSpend"]["ActualSpend"]["Amount"]))
    forecastedSpend = int(float(resp["Budget"]["CalculatedSpend"]["ForecastedSpend"]["Amount"]))

    if resp["Budget"]["BudgetLimit"]["Unit"] == "USD":
        budgetLimitUnit = "$"

    if resp["Budget"]["CalculatedSpend"]["ActualSpend"]["Unit"] == "USD":
        actualSpendUnit = "$"

    if resp["Budget"]["CalculatedSpend"]["ForecastedSpend"]["Unit"] == "USD":
        forecastedSpendUnit = "$"

    for x in resp2["Notifications"]:
        # If a threshold has breached, report it, otherwise move on.
        if x["NotificationState"] != "OK":
            exceededType = x["NotificationType"]
            exceededOperator = x["ComparisonOperator"]
            exceededThreshold = x["Threshold"]

            # Set a critical if an "Actual" threshold is breached.
            if (exceededType == "ACTUAL"):
                criticalState = True
            # Set a warning if an "Forecasted" threshold is breached.
            if (exceededType == "FORECASTED"):
                warningState = True
            
            # Prepare and add to the output report string.
            exceededReport = exceededReport + (f"{exceededType}_{exceededOperator}_{exceededThreshold} ")

    # Build the performance data string
    outputPerfData = f"| actual={actualSpend}$ forecasted={forecastedSpend}$"

    # Output to the calling programme.
    if criticalState == True: # Actual threshold(s) breached
        print(f"CRITICAL - {budgetName} - L:{budgetLimitUnit}{budgetLimit} A:{actualSpendUnit}{actualSpend} F:{forecastedSpendUnit}{forecastedSpend} - {dateTime} - Issues: {exceededReport} {outputPerfData}")
        checkOutputStatus = 2
        sys.exit(checkOutputStatus)
    else:
        if warningState == True: # Forecasated threshold(s) breached
            print(f"WARNING - {budgetName} - L:{budgetLimitUnit}{budgetLimit} A:{actualSpendUnit}{actualSpend} F:{forecastedSpendUnit}{forecastedSpend} - {dateTime} - Issues: {exceededReport} {outputPerfData}")
            checkOutputStatus = 1
            sys.exit(checkOutputStatus)
        else: # No thresholds breached
            print(f"OK - {budgetName} - L:{budgetLimitUnit}{budgetLimit} A:{actualSpendUnit}{actualSpend} F:{forecastedSpendUnit}{forecastedSpend} - {dateTime} - Issues: None {outputPerfData}")
            checkOutputStatus = 0
            sys.exit(checkOutputStatus)
    
# Collect and report the status
if __name__ == "__main__":
    main()

