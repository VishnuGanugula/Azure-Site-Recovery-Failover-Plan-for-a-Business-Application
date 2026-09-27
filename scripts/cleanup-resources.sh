#!/bin/bash
# ==============================================================================
# Script Name: cleanup-resources.sh
# Purpose    : Teardown primary and DR resource groups
# Project    : SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery
# ==============================================================================

set -e

PROD_RG="RG-ASR-24CC3046"
DR_RG="RG-ASR-24CC3046-DR"

echo "======================================================================"
echo "⚠️  WARNING: TEARDOWN OF ALL SPENDWISE ASR DEMO RESOURCES"
echo "======================================================================"
read -p "Are you sure you want to delete '$PROD_RG' and '$DR_RG'? (y/N) " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "--> Deleting Primary Resource Group ($PROD_RG)..."
    az group delete --name "$PROD_RG" --yes --no-wait

    echo "--> Deleting DR Resource Group ($DR_RG)..."
    az group delete --name "$DR_RG" --yes --no-wait

    echo "======================================================================"
    echo "✅ Teardown requests submitted to Azure asynchronously."
    echo "======================================================================"
else
    echo "Teardown cancelled."
fi
