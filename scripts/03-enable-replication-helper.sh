#!/bin/bash
# ==============================================================================
# Script Name: 03-enable-replication-helper.sh
# Purpose    : Helper guidance & status verification for ASR 3-Tier Replication
# Project    : SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery
# ==============================================================================

set -e

PROD_RG="RG-ASR-24CC3046"
DR_RG="RG-ASR-24CC3046-DR"
VAULT_NAME="RSV-ASR-24CC3046"

echo "======================================================================"
echo "ℹ️  PHASE 3 HELPER: SpendWise ASR 3-Tier Replication & Vault Status"
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
echo "1. Go to Azure Portal -> Resource Groups -> RG-ASR-24CC3046"
echo "2. Select 'VM-WEB' -> Under Operations, click 'Disaster recovery'"
echo "3. Target region: Select 'India South Central'"
echo "4. Target Resource Group: Select 'RG-ASR-24CC3046-DR'"
echo "5. Target Virtual Network: Select 'VNET-ASR-TEST'"
echo "6. Target Subnet: Select 'SUBNET-TEST'"
echo "7. Click 'Review + Start replication'"
echo "8. Repeat steps 2-7 for 'VM-APP' and 'VM-DB'"
echo "======================================================================"
