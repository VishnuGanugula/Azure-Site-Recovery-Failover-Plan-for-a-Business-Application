<#
.SYNOPSIS
    Azure Automation PowerShell Runbook for ASR Post-Action Network Cutover.
.DESCRIPTION
    Attaches a pre-created Public IP address in the Disaster Recovery (DR) region
    to the newly spun-up Web VM NIC during an Azure Site Recovery (ASR) failover.
.NOTES
    AZ-104 Hackathon Project: Azure Site Recovery Automation
    Author: AZ-104 Hackathon Team
#>

Param(
    # ASR passes context JSON data to this parameter automatically during Recovery Plan execution
    [object]$RecoveryPlanContext
)

# 1. Configure Error Handling Preference
$ErrorActionPreference = "Stop"

Write-Output "======================================================================"
Write-Output "🚀 AZURE SITE RECOVERY: POST-FAILOVER NETWORK CUTOVER RUNBOOK"
Write-Output "======================================================================"

# 2. Authenticate using Automation Account System-Assigned Managed Identity
try {
    Write-Output "[STEP 1/5] Authenticating to Azure via System-Assigned Managed Identity..."
    Disable-AzContextAutosave -Scope Process | Out-Null
    
    # Connect using Managed Identity
    $AuthResult = Connect-AzAccount -Identity
    Write-Output "✅ Authenticated successfully as Subscription: $($AuthResult.Context.Subscription.Name)"
}
catch {
    Write-Error "❌ Authentication Failed! Ensure System-Assigned Managed Identity is enabled on the Automation Account and assigned 'Network Contributor' role."
    throw $_
}

# 3. Define DR Target Environment Variables
# In production, variables can be extracted dynamically from $RecoveryPlanContext.
# Statically defining them guarantees rapid success during hackathon demos.
$TargetResourceGroup = "Contoso-App-DR-RG"
$TargetVmName        = "Web-VM"
$DrPublicIpName      = "Web-VM-DR-PIP"

Write-Output "[STEP 2/5] Target Resource Group : $TargetResourceGroup"
Write-Output "           Target Virtual Machine: $TargetVmName"
Write-Output "           Target Public IP Name : $DrPublicIpName"

try {
    # 4. Fetch Target VM & Primary NIC
    Write-Output "[STEP 3/5] Querying Target VM details from Azure..."
    $VM = Get-AzVM -ResourceGroupName $TargetResourceGroup -Name $TargetVmName
    
    if ($null -eq $VM) {
        throw "Target VM '$TargetVmName' was not found in Resource Group '$TargetResourceGroup'."
    }

    $NicId = $VM.NetworkProfile.NetworkInterfaces[0].Id
    $NicName = ($NicId -split '/')[-1]
    Write-Output "           Identified Target Network Interface: $NicName"

    $NIC = Get-AzNetworkInterface -ResourceGroupName $TargetResourceGroup -Name $NicName

    # 5. Retrieve Pre-created DR Public IP Address
    Write-Output "[STEP 4/5] Retrieving DR Public IP ($DrPublicIpName)..."
    $PublicIP = Get-AzPublicIpAddress -ResourceGroupName $TargetResourceGroup -Name $DrPublicIpName

    if ($null -eq $PublicIP) {
        throw "Public IP '$DrPublicIpName' not found in Resource Group '$TargetResourceGroup'."
    }

    Write-Output "           Found Public IP Address: $($PublicIP.IpAddress)"

    # 6. Attach Public IP to NIC's primary IP Configuration
    Write-Output "[STEP 5/5] Attaching Public IP to NIC primary IP configuration..."
    $NIC.IpConfigurations[0].PublicIpAddress = $PublicIP

    # Commit network updates back to Azure Resource Manager
    Set-AzNetworkInterface -NetworkInterface $NIC | Out-Null

    Write-Output "======================================================================"
    Write-Output "✅ SUCCESS: DR Network Cutover Complete!"
    Write-Output "🌐 Application is now accessible at DR Public IP: http://$($PublicIP.IpAddress)"
    Write-Output "======================================================================"
}
catch {
    Write-Error "❌ An error occurred during network cutover: $_"
    throw $_
}
