#!/bin/bash
# ==============================================================================
# Script Name: 2-deploy-dr-infra.sh
# Purpose    : Rapid deployment of Target DR Infrastructure & Recovery Services Vault (West US)
# Project    : AZ-104 Hackathon - Azure Site Recovery (ASR) Failover
# ==============================================================================

set -e

# Configuration Variables
DR_RESOURCE_GROUP="Contoso-App-DR-RG"
DR_LOCATION="westus"
PROD_RESOURCE_GROUP="Contoso-App-Prod-RG"
PROD_LOCATION="eastus"

VNET_DR_NAME="VNet-DR"
VNET_DR_PREFIX="10.1.0.0/16"
SUBNET_DR_WEB_NAME="Subnet-Web-DR"
SUBNET_DR_WEB_PREFIX="10.1.1.0/24"
SUBNET_DR_DB_NAME="Subnet-DB-DR"
SUBNET_DR_DB_PREFIX="10.1.2.0/24"

NSG_DR_NAME="NSG-DR-Web"
VAULT_NAME="Contoso-ASR-Vault"
DR_PUBLIC_IP_NAME="Web-VM-DR-PIP"
AUTOMATION_ACCT="Contoso-ASR-AutoAccount"
CACHE_STORAGE_NAME="asrcache$RANDOM"

echo "======================================================================"
echo "🚀 PHASE 1B: Deploying Disaster Recovery Infrastructure ($DR_LOCATION)"
echo "======================================================================"

# 1. Create DR Resource Group
echo "--> Creating DR Resource Group: $DR_RESOURCE_GROUP..."
az group create --name "$DR_RESOURCE_GROUP" --location "$DR_LOCATION" --output table

# 2. Create Cache Storage Account in Primary Region (Required by ASR)
echo "--> Creating ASR Cache Storage Account ($CACHE_STORAGE_NAME in $PROD_LOCATION)..."
az storage account create \
  --name "$CACHE_STORAGE_NAME" \
  --resource-group "$PROD_RESOURCE_GROUP" \
  --location "$PROD_LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --output table

# 3. Create DR Network Security Group
echo "--> Creating DR NSG: $NSG_DR_NAME..."
az network nsg create --resource-group "$DR_RESOURCE_GROUP" --name "$NSG_DR_NAME" --location "$DR_LOCATION" --output table

echo "--> Adding DR NSG Rule for HTTP (Port 80)..."
az network nsg rule create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --nsg-name "$NSG_DR_NAME" \
  --name Allow-HTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --output table

echo "--> Adding DR NSG Rule for SSH (Port 22)..."
az network nsg rule create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --nsg-name "$NSG_DR_NAME" \
  --name Allow-SSH \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 22 \
  --output table

# 4. Create DR Virtual Network & Subnets
echo "--> Creating DR VNet: $VNET_DR_NAME ($VNET_DR_PREFIX)..."
az network vnet create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$VNET_DR_NAME" \
  --address-prefix "$VNET_DR_PREFIX" \
  --subnet-name "$SUBNET_DR_WEB_NAME" \
  --subnet-prefix "$SUBNET_DR_WEB_PREFIX" \
  --location "$DR_LOCATION" \
  --output table

echo "--> Creating DR DB Subnet: $SUBNET_DR_DB_NAME ($SUBNET_DR_DB_PREFIX)..."
az network vnet subnet create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --vnet-name "$VNET_DR_NAME" \
  --name "$SUBNET_DR_DB_NAME" \
  --address-prefix "$SUBNET_DR_DB_PREFIX" \
  --output table

echo "--> Associating NSG to DR Web Subnet..."
az network vnet subnet update \
  --resource-group "$DR_RESOURCE_GROUP" \
  --vnet-name "$VNET_DR_NAME" \
  --name "$SUBNET_DR_WEB_NAME" \
  --network-security-group "$NSG_DR_NAME" \
  --output table

# 5. Pre-create Public IP for Cutover
echo "--> Pre-creating DR Public IP ($DR_PUBLIC_IP_NAME)..."
az network public-ip create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$DR_PUBLIC_IP_NAME" \
  --location "$DR_LOCATION" \
  --sku Standard \
  --allocation-method Static \
  --output table

# 6. Create Recovery Services Vault
echo "--> Creating Recovery Services Vault ($VAULT_NAME)..."
az backup vault create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$VAULT_NAME" \
  --location "$DR_LOCATION" \
  --output table

# 7. Create Automation Account & Managed Identity
echo "--> Creating Automation Account ($AUTOMATION_ACCT)..."
az automation account create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$AUTOMATION_ACCT" \
  --location "$DR_LOCATION" \
  --sku Free \
  --output table

echo "--> Enabling System-Assigned Managed Identity for Automation Account..."
PRINCIPAL_ID=$(az automation account identity assign \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$AUTOMATION_ACCT" \
  --query principalId -o tsv)

echo "Managed Identity Principal ID: $PRINCIPAL_ID"

echo "--> Assigning 'Network Contributor' Role to Automation Account..."
DR_RG_ID=$(az group show --name "$DR_RESOURCE_GROUP" --query id -o tsv)

az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Network Contributor" \
  --scope "$DR_RG_ID" \
  --output table

echo "======================================================================"
echo "✅ DISASTER RECOVERY INFRASTRUCTURE DEPLOYMENT COMPLETE!"
echo "======================================================================"
echo "DR Resource Group  : $DR_RESOURCE_GROUP"
echo "DR Location        : $DR_LOCATION"
echo "Target VNet        : $VNET_DR_NAME ($VNET_DR_PREFIX)"
echo "Recovery Vault     : $VAULT_NAME"
echo "Automation Account : $AUTOMATION_ACCT"
echo "Pre-created DR PIP : $DR_PUBLIC_IP_NAME"
echo "Cache Storage      : $CACHE_STORAGE_NAME"
echo "======================================================================"
