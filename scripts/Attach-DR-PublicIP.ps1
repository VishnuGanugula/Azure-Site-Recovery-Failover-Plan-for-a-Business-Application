<#
.SYNOPSIS
    Azure Automation PowerShell Runbook for SpendWise Post-Action Network Cutover.
.DESCRIPTION
    Attaches a pre-created Public IP address in India South Central
    to the newly spun-up VM-WEB-test NIC during an Azure Site Recovery (ASR) failover.
.NOTES
    SpendWise 3-Tier Disaster Recovery Project
    Authors: G Vishnu (Lead), G Praneeth, Ch Mohan Krishna, K Yeswanth
#>

Param(
    [object]$RecoveryPlanContext
)

$ErrorActionPreference = "Stop"

Write-Output "======================================================================"
Write-Output "🚀 AZURE SITE RECOVERY: SPENDWISE POST-FAILOVER NETWORK CUTOVER"
Write-Output "======================================================================"

# 1. Authenticate using Automation Account System-Assigned Managed Identity
try {
    Write-Output "[STEP 1/4] Authenticating to Azure via System-Assigned Managed Identity..."
    Disable-AzContextAutosave -Scope Process | Out-Null
    $AuthResult = Connect-AzAccount -Identity
    Write-Output "✅ Authenticated successfully as Subscription: $($AuthResult.Context.Subscription.Name)"
}
catch {
    Write-Error "❌ Authentication Failed! Ensure System-Assigned Managed Identity is enabled on the Automation Account."
    throw $_
}

# 2. Define DR Target Environment Variables
$TargetResourceGroup = "RG-ASR-24CC3046-DR"
$TargetVmName        = "VM-WEB-test"
$DrPublicIpName      = "VM-WEB-DR-PIP"

Write-Output "[STEP 2/4] Target Resource Group : $TargetResourceGroup"
Write-Output "           Target Virtual Machine: $TargetVmName"
Write-Output "           Target Public IP Name : $DrPublicIpName"

try {
    # 3. Fetch Target VM & Primary NIC
    Write-Output "[STEP 3/4] Querying Target VM details..."
    $VM = Get-AzVM -ResourceGroupName $TargetResourceGroup -Name $TargetVmName
    
    if ($null -eq $VM) {
        throw "Target VM '$TargetVmName' was not found in Resource Group '$TargetResourceGroup'."
    }

    $NicId = $VM.NetworkProfile.NetworkInterfaces[0].Id
    $NicName = ($NicId -split '/')[-1]
    Write-Output "           Identified Target Network Interface: $NicName"

    $NIC = Get-AzNetworkInterface -ResourceGroupName $TargetResourceGroup -Name $NicName

    # 4. Attach Public IP to NIC
    Write-Output "[STEP 4/4] Retrieving & binding DR Public IP ($DrPublicIpName)..."
    $PublicIP = Get-AzPublicIpAddress -ResourceGroupName $TargetResourceGroup -Name $DrPublicIpName

    if ($null -eq $PublicIP) {
        throw "Public IP '$DrPublicIpName' not found in Resource Group '$TargetResourceGroup'."
    }

    $NIC.IpConfigurations[0].PublicIpAddress = $PublicIP
    Set-AzNetworkInterface -NetworkInterface $NIC | Out-Null

    Write-Output "======================================================================"
    Write-Output "✅ SUCCESS: DR Network Cutover Complete!"
    Write-Output "🌐 SpendWise Web App accessible at DR Public IP: http://$($PublicIP.IpAddress)"
    Write-Output "======================================================================"
}
catch {
    Write-Error "❌ An error occurred during network cutover: $_"
    throw $_
}
