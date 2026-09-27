# 🎤 SpendWise 3-Tier Azure Site Recovery (ASR) Pitch Deck & Review Guide

## Project Title: Three-Tier SpendWise Disaster Recovery Project using Azure Site Recovery

### Team Members & Roles
- **2400030408 - G Vishnu** (Team Lead)
- **2400030412 - G Praneeth**
- **2400030233 - Ch Mohan Krishna**
- **2400030418 - K Yeswanth**

---

## ⏱️ 5-Minute Timed Presentation Pitch Schedule

```text
+-----------------------------------------------------------------------------------+
| TIME          | SLIDE / SECTION               | KEY DEMONSTRATION FOCUS           |
+-----------------------------------------------------------------------------------+
| 0:00 - 0:45   | 1. Executive Summary & Challenge| SpendWise 3-Tier Disaster Recovery|
| 0:45 - 1:45   | 2. Architecture & Fabric Mapping| Central India -> India South Central|
| 1:45 - 3:00   | 3. Sequenced DR Failover Demo | RP-3TIER-APP (DB -> APP -> WEB)    |
| 3:00 - 4:00   | 4. Post-Failover Diagnostics | app.py DB IP & pg_hba.conf fix    |
| 4:00 - 5:00   | 5. Empirical Results & Q&A    | RTO: 5m 24s | Health HTTP 200 OK  |
+-----------------------------------------------------------------------------------+
```

---

## 📽️ Slide Breakdown & Speaker Script

### Slide 1: Executive Summary & Problem Statement
- **Speaker Script:**
  > *"Unplanned datacenter outages threaten enterprise web applications. For our project, we engineered a complete cross-region Disaster Recovery solution for the **SpendWise 3-Tier Application** using **Azure Site Recovery (ASR)**. Our primary workload runs in **Central India** across three dedicated tiers: Database, Application, and Web. ASR continuously replicates disk state to **India South Central** with zero standby compute costs."*

### Slide 2: 3-Tier Architecture & Azure Governance
- **Speaker Script:**
  > *"Our solution spans all 5 AZ-104 domains:
  > 1. **Identities & Governance:** Resource isolation between `RG-ASR-24CC3046` and `RG-ASR-24CC3046-DR`.
  > 2. **Storage:** Continuous block-level replication of managed disks via ASR cache staging accounts.
  > 3. **Compute:** Ubuntu VMs verified inside guest OS running Linux kernel `5.15.0-1003-azure`.
  > 4. **Networking:** Network isolation in `VNET-ASR-TEST` / `SUBNET-TEST` (`10.30.1.0/24`).
  > 5. **Monitoring & Recovery:** Recovery Services Vault `RSV-ASR-24CC3046` and 3-Boot Group plan `RP-3TIER-APP`."*

### Slide 3: Sequenced Recovery Plan & REST API Execution
- **Speaker Script:**
  > *"Multi-tier applications require sequenced boot ordering: if the web server boots before the database is listening, connections fail. Recovery Plan `RP-3TIER-APP` orchestrates Group 1 (`VM-DB`), Group 2 (`VM-APP`), and Group 3 (`VM-WEB`). We initiated test failover using direct ARM REST API calls in **5 minutes 24 seconds** with zero errors!"*

### Slide 4: Real-World In-Guest Technical Fixes
- **Speaker Script:**
  > *"In real-world disaster recovery, VM startup is only half the battle. When our test VMs booted:
  > 1. We reconfigured `app.py` on `VM-APP-test` to point from primary IP `10.10.3.4` to DR DB IP `10.30.1.4`.
  > 2. We updated PostgreSQL `pg_hba.conf` on `VM-DB-test` to authorize recovery subnet `10.30.1.0/24`.
  > 3. Our end-to-end health endpoint returned `HTTP 200 OK` with status `healthy` and database `connected`!"*

### Slide 5: Measured RTO/RPO Metrics & Review Conclusion
- **Speaker Script:**
  > *"Empirical Execution Summary:
  > - **Recovery Time Objective (RTO):** 5 minutes 24 seconds (Job 7df5bc18... Succeeded).
  > - **Recovery Point Objective (RPO):** < 30 seconds continuous A2A disk sync.
  > - **Application Health:** Verified HTTP 200 via `VM-WEB-test` calling `http://10.30.1.5:5000/health`."*

---

## 💡 Reviewer Q&A Cheat Sheet

| Question | Winning Technical Answer |
| :--- | :--- |
| **Why is startup grouping necessary?** | *"Database services must be online before application workers initialize. Boot Group 1 starts `VM-DB-test`, Group 2 starts `VM-APP-test`, and Group 3 starts `VM-WEB-test`."* |
| **Why use ARM REST API for test failover?** | *"The installed Azure CLI extension lacked the `test-failover` subcommand under `recovery-plan`. Executing `az rest` against the ARM management endpoint enabled zero-impact test execution."* |
| **How was database authentication handled in DR?** | *"PostgreSQL `pg_hba.conf` blocks unauthorized client subnets. We added `10.30.1.0/24 scram-sha-256` to grant authentication rights to the recovered app tier."* |
| **Did kernel compatibility affect ASR?** | *"Yes, we verified guest kernel compatibility inside the OS using `az vm run-command`, switching `VM-WEB` from kernel 6.8 to `5.15.0-1003-azure` before protection."* |
