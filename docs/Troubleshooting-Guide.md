# 🔧 Real-World Diagnostic & Troubleshooting Guide

This guide documents the actual technical issues, diagnostic procedures, command failures, and root-cause solutions encountered during the execution of the **SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery Project**.

---

## 1. Guest Linux Kernel Compatibility & In-Guest Verification

### Problem / Observation
During preparation of `VM-WEB`, the initial kernel reported by the OS was `6.8.0-1064-azure`. To guarantee full ASR mobility agent compatibility, a `5.15` series Azure kernel was required.

### Diagnostic & Fix Sequence
1. **Initial Kernel Inspection:**
   ```bash
   az vm run-command invoke -g RG-ASR-24CC3046 -n VM-WEB \
     --command-id RunShellScript --scripts "uname -r"
   # Output: 6.8.0-1064-azure
   ```
2. **Package Installation:**
   ```bash
   az vm run-command invoke -g RG-ASR-24CC3046 -n VM-WEB \
     --command-id RunShellScript \
     --scripts "sudo apt-get update && sudo apt-get install -y linux-image-5.15.0-1003-azure"
   ```
3. **In-Guest Kernel Verification:**
   ```bash
   az vm run-command invoke -g RG-ASR-24CC3046 -n VM-WEB \
     --command-id RunShellScript --scripts "uname -r"
   # Output: 5.15.0-1003-azure
   ```

> [!IMPORTANT]
> **Key Architectural Takeaway:** Package installation output alone does not prove that the operating system has booted into the target kernel. The second `uname -r` execution directly inside the guest provided empirical proof of the running kernel state.

---

## 2. Recovery Plan Creation Syntax Error (`az site-recovery recovery-plan create`)

### Problem / Observation
The initial Azure CLI command to create the recovery plan failed:
```bash
az site-recovery recovery-plan create -g RG-ASR-24CC3046 \
  --vault-name RSV-ASR-24CC3046 \
  --name RP-3TIER-APP \
  --source-fabric FABRIC-CENTRALINDIA \
  --target-fabric FABRIC-DR-ISC
```
**Error Received:**
`Error: the following arguments are required: --groups, --primary-fabric-id, --recovery-fabric-id`

### Root Cause
The installed version of `az site-recovery` required explicit ARM resource ID references for `--primary-fabric-id` and `--recovery-fabric-id`, along with a JSON-formatted `--groups` payload.

### Solution
Retrieve full fabric resource IDs into shell variables and specify all three Boot groups (`PI-VM-DB`, `PI-VM-APP`, `PI-VM-WEB`):
```bash
PRIMARY=$(az site-recovery fabric show -g RG-ASR-24CC3046 --vault-name RSV-ASR-24CC3046 -n FABRIC-CENTRALINDIA --query id -o tsv)
RECOVERY=$(az site-recovery fabric show -g RG-ASR-24CC3046 --vault-name RSV-ASR-24CC3046 -n FABRIC-DR-ISC --query id -o tsv)

az site-recovery recovery-plan create -g RG-ASR-24CC3046 \
  --vault-name RSV-ASR-24CC3046 \
  --name RP-3TIER-APP \
  --primary-fabric-id "$PRIMARY" \
  --recovery-fabric-id "$RECOVERY" \
  --failover-deployment-model ResourceManager \
  --groups '<groups JSON containing PI-VM-DB, PI-VM-APP, PI-VM-WEB>'
```

---

## 3. Azure CLI Test Failover Subcommand Missing Workaround

### Problem / Observation
Executing `az site-recovery recovery-plan test-failover -h` returned:
`'test-failover' is misspelled or not recognized by the system.`

### Root Cause
The `az site-recovery` extension installed in the environment did not include the `test-failover` subcommand under `recovery-plan`.

### Solution
Bypass the CLI extension wrapper by issuing a direct HTTP POST request to the Azure Resource Manager (ARM) REST API using `az rest`:
```bash
az rest --method post \
  --url "https://management.azure.com/subscriptions/b5f49426-f4c7-437e-97fc-c29a4ebd1430/resourceGroups/RG-ASR-24CC3046/providers/Microsoft.RecoveryServices/vaults/RSV-ASR-24CC3046/replicationRecoveryPlans/RP-3TIER-APP/testFailover?api-version=2025-02-01" \
  --body @/tmp/test-failover.json
```
**JSON Payload (`/tmp/test-failover.json`):**
```json
{
  "properties": {
    "failoverDirection": "PrimaryToRecovery",
    "networkId": "/subscriptions/b5f49426-f4c7-437e-97fc-c29a4ebd1430/resourceGroups/RG-ASR-24CC3046/providers/Microsoft.Network/virtualNetworks/VNET-ASR-TEST",
    "networkType": "VmNetworkAsInput",
    "providerSpecificDetails": [
      {
        "instanceType": "A2A",
        "recoveryPointType": "LatestProcessed"
      }
    ]
  }
}
```

---

## 4. Application Health Endpoint Failure (`HTTP_STATUS=000`)

### Problem / Observation
After test VMs were brought online, initial TCP connectivity check on port 5000 succeeded (`APP_PORT_5000_OK`). However, testing the application health endpoint via curl returned `HTTP_STATUS=000` and `cat: /tmp/health.txt: No such file or directory`.

### Diagnostic Steps
1. **Check Gunicorn Service Status on `VM-APP-test`:**
   ```bash
   az vm run-command invoke -g RG-ASR-24CC3046-DR -n VM-APP-test \
     --command-id RunShellScript \
     --scripts "sudo systemctl status spendwise --no-pager; echo PORT; sudo ss -lntp | grep 5000 || true"
   ```
   *Result:* Gunicorn service was active and listening on `0.0.0.0:5000`, but logs showed:
   `[CRITICAL] WORKER TIMEOUT` / `[ERROR] Worker ... was sent SIGKILL!`

> [!NOTE]
> **Key Concept:** Listening on a socket proves a process is bound to a port; it does NOT guarantee an HTTP endpoint can respond successfully. The `/health` endpoint executes a database connection check, which hung and caused Gunicorn worker timeouts.

2. **Inspect Application Source Code (`/opt/spendwise/app.py`):**
   ```python
   DB_HOST = "10.10.3.4" # Hardcoded production DB IP in Central India
   ```
   *Issue:* The recovered database VM in DR (`VM-DB-test`) was located at `10.30.1.4`, so the application attempted to connect to the offline primary IP `10.10.3.4`.

### Solution
1. **Reconfigure `app.py` DB Host on `VM-APP-test`:**
   ```bash
   sudo sed -i 's/DB_HOST = "10.10.3.4"/DB_HOST = "10.30.1.4"/' /opt/spendwise/app.py
   sudo systemctl restart spendwise
   ```

2. **Fix PostgreSQL Client Authentication (`pg_hba.conf`) on `VM-DB-test`:**
   After updating `app.py`, the health check failed with `no pg_hba.conf entry for host 10.30.1.5`.
   Add DR subnet authentication rule and reload PostgreSQL:
   ```bash
   echo 'host spendwise spenduser 10.30.1.0/24 scram-sha-256' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf
   sudo systemctl reload postgresql
   ```

3. **Final Health Verification Result:**
   ```bash
   curl -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code}\n' http://10.30.1.5:5000/health
   # Returns: {"application":"SpendWise","database":"connected","status":"healthy"}
   # HTTP_STATUS=200
   ```

---

## 5. Test Failover Cleanup Status Distinction

### Problem / Observation
Attempting CLI cleanup via `az site-recovery recovery-plan cleanup-test-failover` returned:
`'cleanup-test-failover' is misspelled or not recognized by the system.`

### Reviewer Status Rule
Do not claim test-failover cleanup is complete based on CLI output when the command fails or is missing. The test failover and functional validation are complete; cleanup remains a separate administrative step performed via Azure Portal or REST API.

> [!TIP]
> In a technical review, a successful `TestFailover` job proves the disaster recovery procedure succeeded. It does not by itself prove that temporary test resources were deleted.
