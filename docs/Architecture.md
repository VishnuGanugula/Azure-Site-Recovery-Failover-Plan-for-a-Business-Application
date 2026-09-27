# 📐 System Architecture & 3-Tier Cross-Region Topology

## 1. High-Level Architecture Overview

The **SpendWise 3-Tier Azure Site Recovery (ASR) Disaster Recovery Solution** implements an active-passive cross-region disaster recovery framework between two Azure paired regions: **Central India (Primary Production)** and **India South Central (Recovery / DR)**.

The protected application models a production enterprise 3-tier workload:
1. **Database Tier (`VM-DB`):** PostgreSQL database engine listening on TCP port `5432` (`10.30.1.4` in DR).
2. **Application Tier (`VM-APP`):** SpendWise Flask Application served via Gunicorn on TCP port `5000` (`10.30.1.5` in DR).
3. **Web Tier (`VM-WEB`):** Web-facing presentation tier forwarding requests to the application layer (`10.30.1.6` in DR).

```mermaid
flowchart TD
    subgraph Client["End Users & External Clients"]
        User["🌐 Client / Application Consumer"]
    end

    subgraph PrimaryRegion["Primary Region: Central India (RG-ASR-24CC3046)"]
        FabricPrimary["Fabric: FABRIC-CENTRALINDIA\nContainer: PC-SOURCE-CENTRALINDIA"]
        
        subgraph ProdVMs["Production Workload"]
            VM_WEB["VM-WEB\n(Web Tier)"]
            VM_APP["VM-APP\n(SpendWise Flask + Gunicorn)"]
            VM_DB["VM-DB\n(PostgreSQL Database)"]
        end

        CacheStorage["ASR Cache Storage Account\n(Standard LRS Delta Staging)"]
        
        VM_WEB -->|HTTP TCP/5000| VM_APP
        VM_APP -->|PostgreSQL TCP/5432| VM_DB
        VM_WEB -.->|Disk Delta Writes| CacheStorage
        VM_APP -.->|Disk Delta Writes| CacheStorage
        VM_DB -.->|Disk Delta Writes| CacheStorage
    end

    subgraph ASRService["Azure Site Recovery Engine"]
        Vault["Recovery Services Vault\nRSV-ASR-24CC3046"]
        Policy["Replication Policy\nPOLICY-A2A-SPENDWISE"]
        RecPlan["Recovery Plan: RP-3TIER-APP\nBoot 1: VM-DB | Boot 2: VM-APP | Boot 3: VM-WEB"]
        
        Vault --- Policy
        Vault --- RecPlan
    end

    subgraph DRRegion["Disaster Recovery Region: India South Central (RG-ASR-24CC3046-DR)"]
        FabricDR["Fabric: FABRIC-DR-ISC\nContainer: PC-DR-ISC"]
        TestVNet["VNet: VNET-ASR-TEST\nSubnet: SUBNET-TEST (10.30.1.0/24)"]

        subgraph DRVMs["Isolated Test Recovery Instances"]
            VM_DB_TEST["VM-DB-test (10.30.1.4)\nPostgreSQL (pg_hba updated)"]
            VM_APP_TEST["VM-APP-test (10.30.1.5)\nFlask + Gunicorn (app.py updated)"]
            VM_WEB_TEST["VM-WEB-test (10.30.1.6)\nWeb / Health Check Tier"]
        end

        TestVNet --- DRVMs
        VM_WEB_TEST -->|TCP/5000 Health Check| VM_APP_TEST
        VM_APP_TEST -->|TCP/5432 Query| VM_DB_TEST
    end

    User ==>|Active Traffic (Normal Mode)| VM_WEB
    CacheStorage ==>|Continuous Asynchronous Delta Replication| DRRegion
    RecPlan -->|Triggers Sequenced Test Failover| DRVMs
```

---

## 2. Component Specifications & Environment Mapping

| Resource Category | Resource Name / Value | Description & Purpose |
| :--- | :--- | :--- |
| **Primary Resource Group** | `RG-ASR-24CC3046` | Primary resource container in Central India (`centralindia`) |
| **Recovery Resource Group** | `RG-ASR-24CC3046-DR` | Target resource container in India South Central (`indiasouthcentral`) |
| **Recovery Services Vault** | `RSV-ASR-24CC3046` | Vault hosting ASR configuration, policies, and orchestration |
| **Primary Fabric / Container** | `FABRIC-CENTRALINDIA` / `PC-SOURCE-CENTRALINDIA` | Primary ASR fabric and logical protection container |
| **Recovery Fabric / Container**| `FABRIC-DR-ISC` / `PC-DR-ISC` | Target ASR recovery fabric and container |
| **Replication Policy** | `POLICY-A2A-SPENDWISE` | Azure-to-Azure replication policy defining retention & sync |
| **Recovery Plan** | `RP-3TIER-APP` | 3-Boot-Group plan ordering DB → APP → WEB recovery |
| **Test Network / Subnet** | `VNET-ASR-TEST` / `SUBNET-TEST` | Isolated DR network (`10.30.1.0/24`) preventing production bleed |
| **Protected Items** | `PI-VM-DB`, `PI-VM-APP`, `PI-VM-WEB` | ASR protected item representations for each tier |

---

## 3. 3-Tier Network & Service Interaction Details

### Tier 1: Database Tier (`VM-DB` / `VM-DB-test`)
- **IP Address (DR):** `10.30.1.4`
- **NIC:** `VM-DBVMNic-test`
- **Service:** PostgreSQL 14 Database
- **Port:** TCP `5432`
- **Post-Failover Adjustment:** Added `host spendwise spenduser 10.30.1.0/24 scram-sha-256` entry to `/etc/postgresql/14/main/pg_hba.conf` and reloaded PostgreSQL service to allow connections from DR app tier.

### Tier 2: Application Tier (`VM-APP` / `VM-APP-test`)
- **IP Address (DR):** `10.30.1.5`
- **NIC:** `VM-APPVMNic-test`
- **Service:** SpendWise Flask Application served by Gunicorn (`spendwise.service`)
- **Port:** TCP `5000`
- **Post-Failover Adjustment:** Modified `/opt/spendwise/app.py` setting `DB_HOST = "10.30.1.4"` (updated from primary IP `10.10.3.4`) and restarted `spendwise.service`.

### Tier 3: Web Tier (`VM-WEB` / `VM-WEB-test`)
- **IP Address (DR):** `10.30.1.6`
- **NIC:** `VM-WEBVMNic-test`
- **Service:** Nginx Web Interface & Application Gateway
- **OS Kernel Verification:** Upgraded kernel from `6.8.0-1064-azure` to `5.15.0-1003-azure` via Azure Run Command.
- **Validation Route:** Calls `http://10.30.1.5:5000/health` and receives HTTP 200 OK.
