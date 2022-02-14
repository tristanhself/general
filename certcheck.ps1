<#

.SYNOPSIS
The script checks the expiry of all certificates or a single certificate within a specific certificate store.

.DESCRIPTION
The script obtains a list of the certificates from a store and then verifies their age, if the certificates are due to expire
within the given age the script will post a critical back to NagiosXI via a passive check to alert system administrators to
take action. The script can return all the certificates within a store and report if any of these are due to expire within the
time period, or you can specify the certificate by its "Subject" (e.g. CN), as seen in the Certificate MMC snap-in. If no specific
certificate subject is given all certificates are returned. The script also takes the NagiosXI service name as an optional argument
so you can customise it if you have multiple certificate or certificate store checks on each host; remember limitations on characters
in NagiosXI service names!

.EXAMPLE
./certcheck.ps1 -certpath <certificatepath> -expirydays <days> [-subjectname <subjectname>] [-servicename <servicename>]

.NOTES
Refer to the NagiosXI documentation on the use of Passive Checks and configuring one with freshness checking against your hosts.

#>

#Set-Executionpolicy RemoteSigned
#Set-StrictMode -Version 2.0

# Collect the arguments from the passed command string, the subject name is optional.
param (
    [Parameter(Mandatory=$true)][string]$certpath,
    [Parameter(Mandatory=$true)][string]$expirydays,
    [string]$subjectname,
    [string]$servicename = "Certificate Expiry Check"
)

# Zero out the count of expired certs.
$expirecount = 0

# Set the postback NRDP URL and token here.
$strURL = "https://nagios.domain.com/nrdp"
$strToken = "<TOKEN>"

# Determine the computer name and stick it in a variable.
$strComputerName = $env:computername
$strComputerName = $strComputerName.ToLower()

Write-Host
Write-Host "Certificate Expiry Check" -ForegroundColor Cyan
Write-Host

########################################################################################################################

# Get the list of certificates from the specified certificate store location.
$certificates = Get-ChildItem -Path $certpath -Recurse -ExpiringInDays $expirydays

# If an object with certificates is returned then process each certificate and post the response to NagiosXI, otherwise
# post back to Nagios that all certificates are due to expire outside of the given days.
if ($certificates) {
    # Process each certificate and print it out.
    foreach ($cert in $certificates) {
        # Check if the certificate matches the one given on the arguments, otherwise show all certificates.
        if ($cert.Subject -eq $subjectname) {
            $expirecount++
            write-host "Subject:"$cert.Subject
            write-host "Friendly Name:"$cert.FriendlyName
            write-host "Expiry Date:"$cert.GetExpirationDateString()
            Write-Host
            break
        } else {
            $expirecount++
            write-host "Subject:"$cert.Subject
            write-host "Friendly Name:"$cert.FriendlyName
            write-host "Expiry Date:"$cert.GetExpirationDateString()
            Write-Host
        }
    }

    Write-Host "CRITICAL - $expirecount certificate(s) due to expire within $expirydays days!" -ForegroundColor Red
    
    # Build the result XML.
$xmlBuilder = @"
<?xml version='1.0'?>
<checkresults>
<checkresult type='service'>
<hostname>$strComputerName</hostname>
<servicename>$servicename</servicename>
<state>2</state>
<output>CRITICAL - $expirecount certificate(s) due to expire within $expirydays days!</output>
</checkresult>
</checkresults>
"@

} else {
    Write-Host "OK - 0 certificate(s) due to expire within $expirydays days." -ForegroundColor Green

    # Build the result XML.
$xmlBuilder = @"
<?xml version='1.0'?>
<checkresults>
<checkresult type='service'>
<hostname>$strComputerName</hostname>
<servicename>$servicename</servicename>
<state>0</state>
<output>OK - $expirecount certificate(s) due to expire within $expirydays days!</output>
</checkresult>
</checkresults>
"@   

}

# Post the result back to NagiosXI.
Write-Host

# Collect together the various variables by creating an object.
$webAgent = New-Object System.Net.WebClient
$nvcWebData = New-Object System.Collections.Specialized.NameValueCollection
$nvcWebData.Add('token', $strToken)
$nvcWebData.Add('cmd', 'submitcheck')
$nvcWebData.Add('XMLDATA', $xmlBuilder)

# Post the result to NagiosXI.
$strWebResponse = $webAgent.UploadValues($strURL, 'POST', $nvcWebData)
$strReturn = [System.Text.Encoding]::ASCII.GetString($strWebResponse)
   if ($strReturn.Contains("<message>OK</message>")) {
        $strMessage = "SUCCESS - checks succesfully sent, NRDP returned: " + $strReturn + ")"
        Write-Host "OK - checks successfully sent!" -ForegroundColor Green
   } else {
        $strMessage = "FAIL! - checks failed to send, NRDP returned: " + $strReturn + ")"
        Write-Host $strMessage -ForegroundColor Red
   }

Write-Host
