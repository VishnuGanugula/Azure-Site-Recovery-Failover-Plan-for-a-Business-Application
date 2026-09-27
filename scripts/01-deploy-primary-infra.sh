#!/bin/bash
# ==============================================================================
# Script Name: 01-deploy-primary-infra.sh
# Purpose    : Rapid deployment of Primary Production Infrastructure (Central India)
# Project    : SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery
# Team       : G Vishnu (Lead), G Praneeth, Ch Mohan Krishna, K Yeswanth
# ==============================================================================

set -e

# Configuration Variables
RESOURCE_GROUP="RG-ASR-24CC3046"
LOCATION="centralindia"
VNET_NAME="VNET-ASR-PROD"
VNET_PREFIX="10.10.0.0/16"
SUBNET_WEB_NAME="SUBNET-WEB"
SUBNET_WEB_PREFIX="10.10.1.0/24"
SUBNET_APP_NAME="SUBNET-APP"
SUBNET_APP_PREFIX="10.10.2.0/24"
SUBNET_DB_NAME="SUBNET-DB"
SUBNET_DB_PREFIX="10.10.3.0/24"
NSG_NAME="NSG-PROD-SPENDWISE"

DB_VM_NAME="VM-DB"
APP_VM_NAME="VM-APP"
WEB_VM_NAME="VM-WEB"
ADMIN_USERNAME="azureuser"

echo "======================================================================"
echo "🚀 PHASE 1: Deploying SpendWise Primary Infrastructure ($LOCATION)"
echo "======================================================================"

# 1. Create Resource Group
echo "--> Creating Resource Group: $RESOURCE_GROUP in $LOCATION..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table

# 2. Create Network Security Group (NSG) and Rules
echo "--> Creating Network Security Group: $NSG_NAME..."
az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" --location "$LOCATION" --output table

echo "--> Adding NSG Rule for HTTP (Port 80)..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-HTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --output table

echo "--> Adding NSG Rule for App Service (Port 5000)..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-APP-5000 \
  --priority 105 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 5000 \
  --output table

echo "--> Adding NSG Rule for PostgreSQL (Port 5432)..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-DB-5432 \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 5432 \
  --output table

echo "--> Adding NSG Rule for SSH (Port 22)..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-SSH \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 22 \
  --output table

# 3. Create Virtual Network & Subnets
echo "--> Creating Virtual Network: $VNET_NAME ($VNET_PREFIX)..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefix "$VNET_PREFIX" \
  --subnet-name "$SUBNET_WEB_NAME" \
  --subnet-prefix "$SUBNET_WEB_PREFIX" \
  --location "$LOCATION" \
  --output table

echo "--> Creating APP Subnet: $SUBNET_APP_NAME ($SUBNET_APP_PREFIX)..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_APP_NAME" \
  --address-prefix "$SUBNET_APP_PREFIX" \
  --output table

echo "--> Creating DB Subnet: $SUBNET_DB_NAME ($SUBNET_DB_PREFIX)..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_DB_NAME" \
  --address-prefix "$SUBNET_DB_PREFIX" \
  --output table

# 4. Deploy 3-Tier Virtual Machines
echo "--> Deploying Database VM ($DB_VM_NAME)..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_DB_NAME" \
  --admin-username "$ADMIN_USERNAME" \
  --generate-ssh-keys \
  --output table

echo "--> Deploying Application VM ($APP_VM_NAME)..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_APP_NAME" \
  --admin-username "$ADMIN_USERNAME" \
  --generate-ssh-keys \
  --output table

echo "--> Deploying Web VM ($WEB_VM_NAME)..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_WEB_NAME" \
  --admin-username "$ADMIN_USERNAME" \
  --generate-ssh-keys \
  --output table

echo "======================================================================"
echo "✅ SPENDWISE PRIMARY INFRASTRUCTURE DEPLOYMENT COMPLETE!"
echo "======================================================================"
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "VNet Name      : $VNET_NAME ($VNET_PREFIX)"
echo "VM Tiers       : $DB_VM_NAME, $APP_VM_NAME, $WEB_VM_NAME"
echo "======================================================================"
