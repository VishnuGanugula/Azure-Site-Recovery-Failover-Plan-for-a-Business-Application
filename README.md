# ☁️ Azure Site Recovery (ASR) Three-Tier SpendWise Disaster Recovery Project

[![AZ-104 Project](https://img.shields.io/badge/AZ--104-Hackathon%20Project-0078D4?logo=microsoftazure&logoColor=white)](https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/)
[![AZ-104 Domains](https://img.shields.io/badge/AZ--104-100%25%20Exam%20Mapped-success)](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Azure-Services.md)
[![Primary Region](https://img.shields.io/badge/Primary-Central%20India-blue)](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Architecture.md)
[![DR Region](https://img.shields.io/badge/Recovery-India%20South%20Central-teal)](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Architecture.md)
[![Measured RTO](https://img.shields.io/badge/RTO-5%20Min%2024%20Sec-brightgreen)](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Failover-Plan.md)

An enterprise-grade **Azure-to-Azure Site Recovery (ASR)** Disaster Recovery solution designed for the 3-Tier **SpendWise** enterprise application. This project demonstrates automated cross-region replication between **Central India** (`centralindia`) and **India South Central** (`indiasouthcentral`), sequenced multi-tier Recovery Plan startup (`VM-DB` → `VM-APP` → `VM-WEB`), guest Linux kernel verification, ARM REST API test failover execution, and post-failover application/database configuration remediation.

---

## 👥 Project Team Members

* **2400030408 - G Vishnu** (Team Lead)
* **2400030412 - G Praneeth**
* **2400030233 - Ch Mohan Krishna**
* **2400030418 - K Yeswanth**

---

## 📂 Repository Directory Structure

```text
.
├── README.md                                         # Master Documentation & Executive Guide
├── SpendWise_Azure_Site_Recovery_Complete_Procedure.pdf  # Primary Project Execution Document
├── docs/                                             # Technical Documentation Suite
│   ├── Project-Abstract.md                           # Project Abstract, Business Goals & Team Roster
│   ├── Architecture.md                               # 3-Tier Architecture & Sequence Diagram
│   ├── Five-Tasks.md                                 # 5 Core AZ-104 Hands-On Tasks Blueprint
│   ├── Failover-Plan.md                              # Operational DR Runbook & Verification Steps
│   ├── Azure-Services.md                             # Service Mapping to AZ-104 Exam Domains
│   ├── Troubleshooting-Guide.md                      # Diagnostics, In-Guest Fixes & REST API Workaround
│   └── Review-Cheat-Sheet.md                         # Review-Day Command Execution Sequence
├── Architecture/                                     # Diagrams & Flowcharts
│   ├── ARCHITECTURE.md                               # Detailed Technical Topology Specification
│   ├── asr-failover-flowchart.html                   # Interactive 3-Tier ASR Visual Flowchart
│   └── azure-to-azure-architecture.png              # Architecture Topology Visual Diagram
├── PPT/                                              # Presentation Assets
│   ├── PITCH_DECK.md                                 # 5-Minute Timed Pitch Script & Q&A Cheat Sheet
│   └── Azure-Site-Recovery-Failover-Plan.pptx        # Presentation Slide Deck
├── Screenshots/                                      # Execution Screenshots & Evidence
│   └── README.md                                     # Evidence Mapping & Screenshots Index
├── scripts/                                          # Automation & Execution Scripts
│   ├── 01-deploy-primary-infra.sh                    # Deploy Central India 3-Tier Workload
│   ├── 01-deploy-primary-infra.azcli                 # Azure CLI Reference for Primary Region
│   ├── 02-deploy-dr-infra.sh                         # Deploy Vault & DR Network in India South Central
│   ├── 02-deploy-dr-infra.azcli                      # Azure CLI Reference for DR Region
│   ├── 03-enable-replication-helper.sh               # Enable A2A Protection & Recovery Plan
│   ├── 04-trigger-test-failover-rest.sh              # Direct ARM REST API Test Failover Script
│   ├── Attach-DR-PublicIP.ps1                        # PowerShell Runbook for Network Cutover
│   ├── cloud-init-primary.txt                        # Cloud-init for App & Database Setup
│   └── cleanup-resources.sh                          # Resource Teardown Script
└── index.html                                        # Interactive Visual Dashboard & Simulator
```

---

## 📐 3-Tier Architecture & Recovery Workflow

```mermaid
flowchart TD
    subgraph Primary["Primary Region: Central India (RG-ASR-24CC3046)"]
        VM_DB["VM-DB (Database Tier)\nPostgreSQL on TCP/5432"]
        VM_APP["VM-APP (Application Tier)\nSpendWise Flask + Gunicorn on TCP/5000"]
        VM_WEB["VM-WEB (Web Tier)\nWeb Gateway"]
        CacheStorage["ASR Cache Storage Account\nStandard LRS Delta Buffer"]

        VM_WEB -->|HTTP TCP/5000| VM_APP
        VM_APP -->|PostgreSQL TCP/5432| VM_DB
        VM_WEB -.-> CacheStorage
        VM_APP -.-> CacheStorage
        VM_DB -.-> CacheStorage
    end

    subgraph ASR Engine["Azure Site Recovery"]
        Vault["Recovery Services Vault\nRSV-ASR-24CC3046"]
        RecPlan["Recovery Plan: RP-3TIER-APP\nGroup 1: DB | Group 2: APP | Group 3: WEB"]
    end

    subgraph DR Region["Target DR Region: India South Central (RG-ASR-24CC3046-DR)"]
        VNetDR["VNet: VNET-ASR-TEST / Subnet: SUBNET-TEST (10.30.1.0/24)"]
        VM_DB_TEST["VM-DB-test (10.30.1.4)\nPostgreSQL (pg_hba updated)"]
        VM_APP_TEST["VM-APP-test (10.30.1.5)\nSpendWise App (app.py updated)"]
        VM_WEB_TEST["VM-WEB-test (10.30.1.6)\nHealth Check Client"]

        VNetDR --- VM_DB_TEST
        VNetDR --- VM_APP_TEST
        VNetDR --- VM_WEB_TEST
        VM_WEB_TEST -->|HTTP 200 Health Check| VM_APP_TEST
        VM_APP_TEST -->|Authenticated Query| VM_DB_TEST
    end

    CacheStorage ==>|Continuous Asynchronous Delta Replication| DR Region
    Vault --> RecPlan
    RecPlan -->|Executes ARM REST Test Failover| DR Region
```

---

## 🎓 AZ-104 Certification Domain Mapping

This project maps directly to official Microsoft Learn guidelines for the **AZ-104 Azure Administrator Associate** certification:

| AZ-104 Exam Domain | Domain Weight | Implementation in Project | Document Link |
| :--- | :--- | :--- | :--- |
| **Domain 1: Identities & Governance** | 15–20% | Resource group isolation (`RG-ASR-24CC3046` vs `RG-ASR-24CC3046-DR`), RBAC management, and managed identities. | [`Azure-Services.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Azure-Services.md) |
| **Domain 2: Implement & Manage Storage** | 15–20% | Managed OS disks (`Standard_LRS`) continuous replication and ASR staging buffer cache storage accounts. | [`Azure-Services.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Azure-Services.md) |
| **Domain 3: Deploy & Manage Compute** | 20–25% | Linux VM deployment, `az vm run-command` guest kernel verification (`5.15.0-1003-azure`), and in-guest config updates. | [`Five-Tasks.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Five-Tasks.md) |
| **Domain 4: Virtual Networking** | 20–25% | Test network isolation (`VNET-ASR-TEST` / `SUBNET-TEST`), subnet routing (`10.30.1.0/24`), and NIC verification. | [`Architecture.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Architecture.md) |
| **Domain 5: Monitor & Maintain Resources**| 10–15% | Recovery Services Vault (`RSV-ASR-24CC3046`), ordered Recovery Plan (`RP-3TIER-APP`), and job monitoring. | [`Failover-Plan.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Failover-Plan.md) |

---

## ⚡ Quick Start & Deployment Sequence

### 1. Deploy Primary Infrastructure (`Central India`)
Run the deployment script to create resource group `RG-ASR-24CC3046` and spin up `VM-DB`, `VM-APP`, and `VM-WEB`:
```bash
chmod +x scripts/*.sh
./scripts/01-deploy-primary-infra.sh
```

### 2. Deploy DR Infrastructure & Vault (`India South Central`)
Deploy the Recovery Services Vault `RSV-ASR-24CC3046`, target network `VNET-ASR-TEST`, and cache storage account:
```bash
./scripts/02-deploy-dr-infra.sh
```

### 3. Configure ASR Replication & Build Recovery Plan
Follow [`docs/Five-Tasks.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Five-Tasks.md) to register container mapping, enable protection for all three VMs, and assemble recovery plan `RP-3TIER-APP`.

### 4. Trigger Test Failover (ARM REST API)
Initiate test failover into the isolated test network using direct REST API execution:
```bash
./scripts/04-trigger-test-failover-rest.sh
```

### 5. Review-Day Demonstration & Health Check
Run the 7-step presentation cheat sheet in [`docs/Review-Cheat-Sheet.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Review-Cheat-Sheet.md) or launch [`index.html`](file:///Users/vishnuganugula/KLU/3.1/Azure/index.html) in your browser for the visual dashboard and interactive failover simulator!

---

## 📈 Measured Business Value & Operational Results

* **Recovery Time Objective (RTO):** **5 minutes 24 seconds** *(Job start 22:04:19 to 22:09:43 UTC)*.
* **Recovery Point Objective (RPO):** **< 30 seconds** *(Continuous block-level delta sync)*.
* **Application Health:** SpendWise endpoint `http://10.30.1.5:5000/health` returning `HTTP 200 OK` (`{"application":"SpendWise","database":"connected","status":"healthy"}`).
* **Idle Cost:** **$0 compute cost** in India South Central secondary region during standby.
