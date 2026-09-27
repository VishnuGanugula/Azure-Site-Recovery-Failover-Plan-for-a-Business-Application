# 📑 Project Abstract: SpendWise 3-Tier Azure Site Recovery (ASR) Failover Plan

## 1. Executive Summary
In modern enterprise cloud computing, system availability and data resilience are critical operational objectives. Unplanned outages caused by regional infrastructure failures, natural disasters, or connectivity disruptions can result in severe financial loss and reputational damage.

This project demonstrates a comprehensive, end-to-end disaster recovery (DR) implementation for **SpendWise**—a production 3-Tier enterprise business application—using **Azure Site Recovery (ASR)**. The primary workload running in **Central India** (`centralindia`) consists of three dedicated virtual machine tiers: Database (`VM-DB`), Application (`VM-APP`), and Web (`VM-WEB`). ASR continuously replicates disk state asynchronously to **India South Central** (`indiasouthcentral`) so that the complete environment can be instantiated and validated following a regional disaster.

---

## 2. Project & Team Information

* **Project Title:** Three-Tier SpendWise Disaster Recovery Project using Azure Site Recovery
* **Primary Region:** Central India (`centralindia`)
* **Recovery Region:** India South Central (`indiasouthcentral`)
* **Recovery Services Vault:** `RSV-ASR-24CC3046`
* **Resource Group:** `RG-ASR-24CC3046` (DR: `RG-ASR-24CC3046-DR`)
* **Recovery Plan:** `RP-3TIER-APP`
* **Test Virtual Network:** `VNET-ASR-TEST` / Subnet: `SUBNET-TEST`

### Team Members
| ID | Name | Role |
| :--- | :--- | :--- |
| **2400030408** | **G Vishnu** | **Team Lead** |
| **2400030412** | G Praneeth | Team Member |
| **2400030233** | Ch Mohan Krishna | Team Member |
| **2400030418** | K Yeswanth | Team Member |

---

## 3. Key Objectives & Architecture Highlights
- **Automated 3-Tier Cross-Region Resilience:** Replicate virtual machines across paired Azure regions from Central India to India South Central.
- **Sequenced Recovery Orchestration:** Ensure multi-tier application dependencies are respected during recovery using ordered Boot groups (Group 1: `VM-DB` → Group 2: `VM-APP` → Group 3: `VM-WEB`).
- **Real-World Application & Database Remediation:** Resolve DR network configuration shifts post-failover, including modifying `app.py` database target IPs and updating PostgreSQL `pg_hba.conf` client authentication rules for the DR subnet (`10.30.1.0/24`).
- **Guest-Level Kernel Compatibility Verification:** Validate and switch guest OS kernels (`5.15.0-1003-azure`) inside Linux VMs using Azure Run Command prior to DR deployment.
- **REST API Test Failover Orchestration:** Utilize direct ARM REST API calls to initiate test failover when CLI subcommands are unavailable.

---

## 4. Key Empirical Metrics & Validation Results
- **Recovery Time Objective (RTO):** **5 minutes 24 seconds** (Measured from job start `22:04:19 UTC` to job completion `22:09:43 UTC`).
- **Recovery Point Objective (RPO):** **< 30 Seconds** (Continuous A2A delta replication).
- **Application Health Check:** `http://10.30.1.5:5000/health` returning `HTTP 200 OK` with payload: `{"application": "SpendWise", "database": "connected", "status": "healthy"}`.
- **Cost Optimization:** **$0 compute cost** in secondary DR region during standby mode.
