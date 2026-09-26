#!/bin/bash
# ==============================================================================
# Script Name: 3-enable-replication-helper.sh
# Purpose    : Helper guidance & status verification for ASR Replication
# Project    : AZ-104 Hackathon - Azure Site Recovery (ASR) Failover
# ==============================================================================

set -e

PROD_RG="Contoso-App-Prod-RG"
DR_RG="Contoso-App-DR-RG"
VAULT_NAME="Contoso-ASR-Vault"

echo "======================================================================"
echo "ℹ️  PHASE 2 HELPER: Azure Site Recovery Enable Replication & Status"
echo "======================================================================"

echo "Checking deployed VMs in Primary Region ($PROD_RG)..."
az vm list --resource-group "$PROD_RG" --query "[].{Name:name, ProvisioningState:provisioningState, PowerState:powerState}" -o table

echo ""
echo "Checking Recovery Services Vault in DR Region ($DR_RG)..."
az backup vault show --resource-group "$DR_RG" --name "$VAULT_NAME" --query "{Name:name, Location:location, Id:id}" -o table

echo ""
echo "======================================================================"
echo "📌 AZURE PORTAL STEPS TO ENABLE REPLICATION (Fastest Method):"
echo "======================================================================"
echo "1. Go to Azure Portal -> Resource Groups -> Contoso-App-Prod-RG"
echo "2. Select 'Web-VM' -> In left menu under Operations, click 'Disaster recovery'"
echo "3. Target region: Select 'West US'"
echo "4. Target Resource Group: Select 'Contoso-App-DR-RG'"
echo "5. Target Virtual Network: Select 'VNet-DR'"
echo "6. Target Subnet: Select 'Subnet-Web-DR'"
echo "7. Cache Storage Account: Select the 'asrcache*' account created in East US"
echo "8. Click 'Review + Start replication'"
echo "9. Repeat steps 2-8 for 'DB-VM' (Target Subnet: 'Subnet-DB-DR')"
echo "======================================================================"
