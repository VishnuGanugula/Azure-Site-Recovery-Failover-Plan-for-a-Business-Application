#!/bin/bash
# ==============================================================================
# Script Name: 04-trigger-test-failover-rest.sh
# Purpose    : Execute Test Failover via ARM REST API for RP-3TIER-APP
# Project    : SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery
# ==============================================================================

set -e

RESOURCE_GROUP="RG-ASR-24CC3046"
VAULT_NAME="RSV-ASR-24CC3046"
RECOVERY_PLAN="RP-3TIER-APP"
TEST_VNET_NAME="VNET-ASR-TEST"
DR_RESOURCE_GROUP="RG-ASR-24CC3046-DR"

echo "======================================================================"
echo "🚀 EXECUTING TEST FAILOVER VIA ARM REST API ($RECOVERY_PLAN)"
echo "======================================================================"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TEST_VNET_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${TEST_VNET_NAME}"

# Prepare JSON Payload
PAYLOAD_FILE="/tmp/test-failover.json"
cat <<EOF > "$PAYLOAD_FILE"
{
  "properties": {
    "failoverDirection": "PrimaryToRecovery",
    "networkId": "${TEST_VNET_ID}",
    "networkType": "VmNetworkAsInput",
    "providerSpecificDetails": [
      {
        "instanceType": "A2A",
        "recoveryPointType": "LatestProcessed"
      }
    ]
  }
}
EOF

echo "--> Target Test Network: $TEST_VNET_ID"
echo "--> Sending HTTP POST request to ARM REST API..."

az rest --method post \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.RecoveryServices/vaults/${VAULT_NAME}/replicationRecoveryPlans/${RECOVERY_PLAN}/testFailover?api-version=2025-02-01" \
  --body "@${PAYLOAD_FILE}"

echo ""
echo "======================================================================"
echo "✅ TEST FAILOVER JOB TRIGGERED SUCCESSFULLY!"
echo "======================================================================"
echo "Monitor job execution using:"
echo "az site-recovery job list -g $RESOURCE_GROUP --vault-name $VAULT_NAME"
echo "======================================================================"
