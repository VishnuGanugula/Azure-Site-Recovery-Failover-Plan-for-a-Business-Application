#!/bin/bash
# ==============================================================================
# Script Name: 1-deploy-base-infra.sh
# Purpose    : Rapid deployment of Primary Production Infrastructure (East US)
# Project    : AZ-104 Hackathon - Azure Site Recovery (ASR) Failover
# ==============================================================================

set -e

# Configuration Variables
RESOURCE_GROUP="Contoso-App-Prod-RG"
LOCATION="eastus"
VNET_NAME="VNet-Prod"
VNET_PREFIX="10.0.0.0/16"
SUBNET_WEB_NAME="Subnet-Web"
SUBNET_WEB_PREFIX="10.0.1.0/24"
SUBNET_DB_NAME="Subnet-DB"
SUBNET_DB_PREFIX="10.0.2.0/24"
NSG_NAME="NSG-Prod-Web"

WEB_VM_NAME="Web-VM"
DB_VM_NAME="DB-VM"
ADMIN_USERNAME="azureuser"

echo "======================================================================"
echo "🚀 PHASE 1A: Deploying Primary Infrastructure ($LOCATION)"
echo "======================================================================"

# 1. Create Resource Group
echo "--> Creating Resource Group: $RESOURCE_GROUP..."
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

echo "--> Adding NSG Rule for SSH (Port 22)..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-SSH \
  --priority 110 \
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

echo "--> Creating DB Subnet: $SUBNET_DB_NAME ($SUBNET_DB_PREFIX)..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_DB_NAME" \
  --address-prefix "$SUBNET_DB_PREFIX" \
  --output table

echo "--> Associating NSG to Web Subnet..."
az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_WEB_NAME" \
  --network-security-group "$NSG_NAME" \
  --output table

# 4. Create Web VM with cloud-init
CLOUD_INIT_PATH="$(dirname "$0")/cloud-init-primary.txt"

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
  --custom-data "$CLOUD_INIT_PATH" \
  --output table

# 5. Create Database VM (Simulated Tier)
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

# 6. Output Deployment Summary
WEB_PIP=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "$WEB_VM_NAME" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo "======================================================================"
echo "✅ PRIMARY INFRASTRUCTURE DEPLOYMENT COMPLETE!"
echo "======================================================================"
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "VNet Name      : $VNET_NAME ($VNET_PREFIX)"
echo "Web VM IP      : http://$WEB_PIP"
echo "SSH Command    : ssh $ADMIN_USERNAME@$WEB_PIP"
echo "======================================================================"
