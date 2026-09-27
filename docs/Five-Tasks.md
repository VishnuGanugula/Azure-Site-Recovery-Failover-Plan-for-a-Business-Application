# 🎯 Five Core Hands-On Tasks (AZ-104 Execution & Execution Blueprint)

This document details the five core execution tasks for deploying, configuring, failing over, and validating the **SpendWise 3-Tier Disaster Recovery Project** using Azure Site Recovery (ASR).

---

## Task 1: Provision 3-Tier Infrastructure & Guest Kernel Verification
* **AZ-104 Domain Alignment:** Domain 3 (Deploy & Manage Compute) & Domain 4 (Configure & Manage Virtual Networking).
* **Objective:** Deploy production VMs (`VM-DB`, `VM-APP`, `VM-WEB`) in `RG-ASR-24CC3046` (`centralindia`) and verify guest Linux kernel compatibility.
* **Execution Steps:**
  1. Provision `VM-DB`, `VM-APP`, and `VM-WEB` in Central India with appropriate subnets and NSGs.
  2. Execute Azure Run Command on `VM-WEB` to check guest Linux kernel version:
     ```bash
     az vm run-command invoke -g RG-ASR-24CC3046 -n VM-WEB \
       --command-id RunShellScript --scripts "uname -r"
     ```
  3. Install supported Azure 5.15 kernel on `VM-WEB` and verify active boot kernel inside guest:
     ```bash
     az vm run-command invoke -g RG-ASR-24CC3046 -n VM-WEB \
       --command-id RunShellScript --scripts "sudo apt-get update && sudo apt-get install -y linux-image-5.15.0-1003-azure"
     ```
* **Empirical Verification:** Guest reboot verified running `5.15.0-1003-azure` directly via `uname -r` execution inside the OS.

---

## Task 2: Configure Replication Policy, Container Mapping & Enable ASR Protection
* **AZ-104 Domain Alignment:** Domain 2 (Implement & Manage Storage) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Establish replication infrastructure inside Recovery Services Vault `RSV-ASR-24CC3046` and protect all three VM tiers.
* **Execution Steps:**
  1. Define replication policy `POLICY-A2A-SPENDWISE` and register primary fabric `FABRIC-CENTRALINDIA` and recovery fabric `FABRIC-DR-ISC`.
  2. Map primary protection container `PC-SOURCE-CENTRALINDIA` to recovery container `PC-DR-ISC`.
  3. Create ASR protected items (`PI-VM-DB`, `PI-VM-APP`, `PI-VM-WEB`):
     ```bash
     az site-recovery protected-item create -g RG-ASR-24CC3046 \
       --vault-name RSV-ASR-24CC3046 \
       --fabric-name FABRIC-CENTRALINDIA \
       --name PI-VM-WEB \
       --protection-container PC-SOURCE-CENTRALINDIA \
       --policy-id "/subscriptions/.../replicationPolicies/POLICY-A2A-SPENDWISE" \
       --provider-details "$(cat /tmp/vm-web-details.json)"
     ```
* **Empirical Verification:** State query confirms all 3 VMs transition from `InitialReplicationInProgress` to `Protected` with `Normal` replication health:
  ```text
  VM        State      Health
  ------    ---------  --------
  VM-WEB    Protected  Normal
  VM-APP    Protected  Normal
  VM-DB     Protected  Normal
  ```

---

## Task 3: Construct Sequenced 3-Tier Recovery Plan (`RP-3TIER-APP`)
* **AZ-104 Domain Alignment:** Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Define a multi-tier recovery plan enforcing ordered boot dependencies (Database → Application → Web).
* **Execution Steps:**
  1. Create Recovery Plan `RP-3TIER-APP` specifying primary fabric `FABRIC-CENTRALINDIA` and target fabric `FABRIC-DR-ISC`:
     ```bash
     az site-recovery recovery-plan create -g RG-ASR-24CC3046 \
       --vault-name RSV-ASR-24CC3046 \
       --name RP-3TIER-APP \
       --primary-fabric-id "$PRIMARY_FABRIC_ID" \
       --recovery-fabric-id "$RECOVERY_FABRIC_ID" \
       --failover-deployment-model ResourceManager \
       --groups '<JSON payload defining Boot groups>'
     ```
  2. Configure three distinct Boot Groups:
     - **Boot Group 1:** `PI-VM-DB` (Database Tier starts first)
     - **Boot Group 2:** `PI-VM-APP` (Application Tier starts after DB is ready)
     - **Boot Group 3:** `PI-VM-WEB` (Web Tier starts last)
* **Empirical Verification:** Query `az site-recovery recovery-plan show` returning 3 distinct `Boot` groups in JSON output.

---

## Task 4: Execute Test Failover via ARM REST API & Verify Network Isolation
* **AZ-104 Domain Alignment:** Domain 4 (Configure & Manage Virtual Networking) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Initiate an isolated test failover into `VNET-ASR-TEST` / `SUBNET-TEST` without impacting production traffic.
* **Execution Steps:**
  1. Because the Azure CLI version did not expose `az site-recovery recovery-plan test-failover`, invoke the ARM REST endpoint directly:
     ```bash
     az rest --method post \
       --url "https://management.azure.com/subscriptions/.../resourceGroups/RG-ASR-24CC3046/providers/Microsoft.RecoveryServices/vaults/RSV-ASR-24CC3046/replicationRecoveryPlans/RP-3TIER-APP/testFailover?api-version=2025-02-01" \
       --body @/tmp/test-failover.json
     ```
  2. Monitor job status via `az site-recovery job show --job-name 7df5bc18-4a2e-40ff-83da-1b21f16ea647`.
* **Empirical Verification:** ASR job status returns `Succeeded` in **5 minutes 24 seconds** (22:04:19 to 22:09:43 UTC). Target test VMs created: `VM-DB-test` (`10.30.1.4`), `VM-APP-test` (`10.30.1.5`), `VM-WEB-test` (`10.30.1.6`) on subnet `SUBNET-TEST`.

---

## Task 5: 3-Tier Application Remediation & End-to-End Validation
* **AZ-104 Domain Alignment:** Domain 3 (Deploy & Manage Compute) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Perform cross-tier network diagnostics, fix application/database configurations, and validate HTTP health status.
* **Execution Steps:**
  1. **TCP Port Connectivity Validation:**
     - Verify `VM-APP-test` → `VM-DB-test` on TCP/5432: `DB_PORT_5432_OK`.
     - Verify `VM-WEB-test` → `VM-APP-test` on TCP/5000: `APP_PORT_5000_OK`.
  2. **Application IP Correction:** Update `/opt/spendwise/app.py` on `VM-APP-test` from production DB IP `10.10.3.4` to DR DB IP `10.30.1.4` and restart `spendwise.service`.
  3. **Database Access Control Correction:** Add recovery subnet access to `/etc/postgresql/14/main/pg_hba.conf` on `VM-DB-test`:
     ```text
     host spendwise spenduser 10.30.1.0/24 scram-sha-256
     ```
     Reload PostgreSQL service.
  4. **End-to-End Health Verification:** Execute curl from `VM-WEB-test`:
     ```bash
     curl -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code}\n' http://10.30.1.5:5000/health
     ```
* **Empirical Verification:** Endpoint returns `HTTP_STATUS=200` with JSON body:
  `{"application":"SpendWise","database":"connected","status":"healthy"}`.
