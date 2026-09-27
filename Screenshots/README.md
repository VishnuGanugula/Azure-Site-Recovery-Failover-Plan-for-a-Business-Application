# 📸 Demonstration Screenshots & Evidence Mapping

This directory contains visual proof of deployment and failover execution for the **SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery Project**.

---

## 📌 Recommended Screenshots Index

1. **`1-primary-infrastructure.png`**
   - Azure Portal view of Resource Group `RG-ASR-24CC3046` in **Central India** showing `VM-DB`, `VM-APP`, `VM-WEB`, and virtual network resources.

2. **`2-dr-infrastructure.png`**
   - Azure Portal view of Resource Group `RG-ASR-24CC3046-DR` in **India South Central** showing `VNET-ASR-TEST` and Recovery Services Vault `RSV-ASR-24CC3046`.

3. **`3-asr-replication-healthy.png`**
   - View of `RSV-ASR-24CC3046` > **Replicated Items** showing `VM-DB`, `VM-APP`, and `VM-WEB` in **Protected** state with **Normal** replication health.

4. **`4-recovery-plan-groups.png`**
   - View of Recovery Plan `RP-3TIER-APP` showing 3 distinct Boot Groups: **Group 1 (VM-DB)**, **Group 2 (VM-APP)**, and **Group 3 (VM-WEB)**.

5. **`5-test-failover-job-success.png`**
   - ASR Job execution history showing Job `7df5bc18-4a2e-40ff-83da-1b21f16ea647` with **Succeeded** status and measured execution duration of **5 minutes 24 seconds**.

6. **`6-dr-test-vms-online.png`**
   - Azure Portal view of recovered test VMs `VM-DB-test` (`10.30.1.4`), `VM-APP-test` (`10.30.1.5`), and `VM-WEB-test` (`10.30.1.6`) inside `SUBNET-TEST`.

7. **`7-application-health-http200.png`**
   - Terminal screenshot of `az vm run-command` invoking curl from `VM-WEB-test` to `http://10.30.1.5:5000/health` returning `HTTP_STATUS=200` and `{"application":"SpendWise","database":"connected","status":"healthy"}`.
