#!/bin/bash
# ==============================================================================
# Script Name: 02-deploy-dr-infra.sh
# Purpose    : Deployment of DR Infrastructure & Recovery Services Vault (India South Central)
# Project    : SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery
# Team       : G Vishnu (Lead), G Praneeth, Ch Mohan Krishna, K Yeswanth
# ==============================================================================

set -e

# Configuration Variables
DR_RESOURCE_GROUP="RG-ASR-24CC3046-DR"
DR_LOCATION="indiasouthcentral"
PROD_RESOURCE_GROUP="RG-ASR-24CC3046"
PROD_LOCATION="centralindia"

VNET_TEST_NAME="VNET-ASR-TEST"
VNET_TEST_PREFIX="10.30.0.0/16"
SUBNET_TEST_NAME="SUBNET-TEST"
SUBNET_TEST_PREFIX="10.30.1.0/24"

VAULT_NAME="RSV-ASR-24CC3046"
CACHE_STORAGE_NAME="asrcache$RANDOM"

echo "======================================================================"
echo "🚀 PHASE 2: Deploying Disaster Recovery Infrastructure ($DR_LOCATION)"
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

# 3. Create Test Failover Virtual Network
echo "--> Creating Test Failover VNet: $VNET_TEST_NAME ($VNET_TEST_PREFIX)..."
az network vnet create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$VNET_TEST_NAME" \
  --address-prefix "$VNET_TEST_PREFIX" \
  --subnet-name "$SUBNET_TEST_NAME" \
  --subnet-prefix "$SUBNET_TEST_PREFIX" \
  --location "$DR_LOCATION" \
  --output table

# 4. Create Recovery Services Vault
echo "--> Creating Recovery Services Vault ($VAULT_NAME in $DR_LOCATION)..."
az backup vault create \
  --resource-group "$DR_RESOURCE_GROUP" \
  --name "$VAULT_NAME" \
  --location "$DR_LOCATION" \
  --output table

echo "======================================================================"
echo "✅ DISASTER RECOVERY INFRASTRUCTURE DEPLOYMENT COMPLETE!"
echo "======================================================================"
echo "DR Resource Group  : $DR_RESOURCE_GROUP"
echo "DR Location        : $DR_LOCATION"
echo "Target Test VNet   : $VNET_TEST_NAME ($VNET_TEST_PREFIX)"
echo "Recovery Vault     : $VAULT_NAME"
echo "Cache Storage      : $CACHE_STORAGE_NAME"
echo "======================================================================"
