# showstoragepsp.ps1 - Path Selection Policy Check Script v1.0 (22/02/2023)
# Tristan Self

<#

.SYNOPSIS
Script to check Path Selection Policy for datastores is the expected setting.

.DESCRIPTION
Script to check Path Selection Policy for datastores is the expected setting.

.EXAMPLE
./showstoragepsp.ps1 -VIServer <FQDN of vCenter> -datastore <Datastore_Name> -expectedPSP <PSP_Type>

./showstoragepsp.ps1 -VIServer vcenter.domain.com -CheckStore datastore100 -expectedPSP NIMBLE_PSP_DIRECTED

.NOTES
None.

#>

###################################################################
# User Variables
###################################################################

# Collect the arguments from the passed command string.
param (
    [string]$VIServer = @(""),
    [string]$datastore = "",
    [string]$expectedPSP = ""
)

# Initalise Variables
$esxHosts = ""
$esxHost = ""

###################################################################
# Perform Connection Operations
###################################################################

Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
Set-PowerCLIConfiguration -Scope Session -WebOperationTimeoutSeconds -1 -confirm:$false | out-null
Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -confirm:$false | out-null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | out-null

# Connect to vCenter server
Write-Host
Write-Host "vCenter:"$VIserver"..." -NoNewLine

try {
    Connect-VIServer $VIserver -ErrorAction stop | out-null
    Write-Host "Connected!" -ForegroundColor Green
    Write-Host
}
catch {
    Write-Host "FAILED!" -ForegroundColor Red
    Write-Host
    exit
}

#####################################################################
# Find Path Selection Policy for Storage or Just One if Specified
#####################################################################

Write-Host "Show Storage Path Selection Policy (PSP)" -ForegroundColor Yellow
Write-Host 
Write-Host "Datastore    : " -NoNewline
Write-Host $datastore -ForegroundColor Magenta
Write-Host "Expected PSP : " -NoNewline
Write-Host $expectedPSP -ForegroundColor Magenta
Write-Host
Write-Host "------------------------------------------------------------------------"
Write-Host

$esxHosts = get-vmhost -datastore $datastore

foreach ($esxHost in $esxHosts) {
    Write-Host $esxHost.Name": " -NoNewline
    $datastorecheck = Get-Datastore -name $datastore
    try {
        $esxcli = Get-EsxCli -VMHost $esxHost -ErrorAction Stop
        $currentPSP = $esxcli.storage.nmp.device.list($datastorecheck.ExtensionData.Info.Vmfs.Extent[0].DiskName) | Select -ExpandProperty PathSelectionPolicy
        if ($currentPSP -eq $expectedPSP) {
            Write-Host $currentPSP -ForegroundColor Green
        } else {
            Write-Host $currentPSP -ForegroundColor Red
        }
    } catch {
        Write-Host "No Data" -ForegroundColor Cyan
    }
}

Write-Host
Write-Host "------------------------------------------------------------------------"
Write-Host

###################################################################
# Disconnect from vCenter
###################################################################

Write-Host "vCenter:" $VIServer"..." -NoNewline
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected" -ForegroundColor Red
Write-Host
