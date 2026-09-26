#!/bin/bash
# ==============================================================================
# Script Name: cleanup-resources.sh
# Purpose    : Teardown all resources after Hackathon presentation
# Project    : AZ-104 Hackathon - Azure Site Recovery (ASR) Failover
# ==============================================================================

echo "======================================================================"
echo "⚠️  TEARDOWN: Deleting Azure Hackathon Resource Groups"
echo "======================================================================"
echo "This will delete: Contoso-App-Prod-RG and Contoso-App-DR-RG"
read -p "Are you sure you want to delete all hackathon resources? (y/N): " confirm

if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "Deleting Contoso-App-Prod-RG..."
  az group delete --name Contoso-App-Prod-RG --no-wait --yes
  
  echo "Deleting Contoso-App-DR-RG..."
  az group delete --name Contoso-App-DR-RG --no-wait --yes

  echo "✅ Cleanup initiated in background!"
else
  echo "Cleanup cancelled."
fi
