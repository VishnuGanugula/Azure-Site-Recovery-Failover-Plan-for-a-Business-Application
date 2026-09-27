# 🎯 Five Core Hands-On Tasks (AZ-104 Execution Blueprint)

> [!NOTE]
> The full task blueprint and execution guide is located in [`docs/Five-Tasks.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Five-Tasks.md).

---

## Task 1: Provision 3-Tier Infrastructure & Guest Kernel Verification
* **AZ-104 Domain Alignment:** Domain 3 (Deploy & Manage Compute) & Domain 4 (Configure & Manage Virtual Networking).
* **Objective:** Deploy production VMs (`VM-DB`, `VM-APP`, `VM-WEB`) in `RG-ASR-24CC3046` (`centralindia`) and verify guest Linux kernel compatibility (`5.15.0-1003-azure`).

---

## Task 2: Configure Replication Policy, Container Mapping & Enable ASR Protection
* **AZ-104 Domain Alignment:** Domain 2 (Implement & Manage Storage) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Establish replication infrastructure inside Recovery Services Vault `RSV-ASR-24CC3046` and protect all three VM tiers (`PI-VM-DB`, `PI-VM-APP`, `PI-VM-WEB`).

---

## Task 3: Construct Sequenced 3-Tier Recovery Plan (`RP-3TIER-APP`)
* **AZ-104 Domain Alignment:** Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Define a multi-tier recovery plan enforcing ordered boot dependencies (Group 1: DB → Group 2: APP → Group 3: WEB).

---

## Task 4: Execute Test Failover via ARM REST API & Verify Network Isolation
* **AZ-104 Domain Alignment:** Domain 4 (Configure & Manage Virtual Networking) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Initiate an isolated test failover into `VNET-ASR-TEST` / `SUBNET-TEST` (`10.30.1.0/24`) using direct ARM REST API calls.

---

## Task 5: 3-Tier Application Remediation & End-to-End Validation
* **AZ-104 Domain Alignment:** Domain 3 (Deploy & Manage Compute) & Domain 5 (Monitor & Maintain Azure Resources).
* **Objective:** Perform cross-tier network diagnostics, fix application `app.py` target IP (`10.30.1.4`) and PostgreSQL `pg_hba.conf` subnet access (`10.30.1.0/24 scram-sha-256`), and validate HTTP 200 health status.
