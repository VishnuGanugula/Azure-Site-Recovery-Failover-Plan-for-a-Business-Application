# 📐 System Architecture & Cross-Region Topology

## 1. High-Level Architecture Overview

The **Azure Site Recovery (ASR) Business Application Failover Plan** implements an active-passive disaster recovery framework across two distinct Azure paired regions: **East US (Primary Production)** and **West US (Secondary Disaster Recovery)**.

The solution models an enterprise **2-Tier Application**:
- **Web Tier:** Nginx Web Server deployed on Linux (`Ubuntu 22.04 LTS`).
- **Database Tier:** Simulated relational database server running on Linux (`Ubuntu 22.04 LTS`).

```mermaid
flowchart TD
    subgraph Client["Users & External Traffic"]
        User["🌐 End User / Client"]
    end

    subgraph PrimaryRegion["Primary Region: East US (Contoso-App-Prod-RG)"]
        VNetProd["VNet-Prod (10.0.0.0/16)"]
        
        subgraph WebSubnet["Subnet-Web (10.0.1.0/24)"]
            NSGProd["NSG-Prod-Web (Ports 80, 22)"]
            WebVM["Web-VM (10.0.1.4)\nUbuntu 22.04 + Nginx"]
        end

        subgraph DBSubnet["Subnet-DB (10.0.2.0/24)"]
            DBVM["DB-VM (10.0.2.4)\nDatabase Tier"]
        end

        CacheStorage["Cache Storage Account\n(asrcache* - Standard LRS)"]
        
        WebVM -->|State / Reads| DBVM
        WebVM -.->|Disk Writes| CacheStorage
        DBVM -.->|Disk Writes| CacheStorage
    end

    subgraph ASRService["Azure Site Recovery Engine"]
        Vault["Recovery Services Vault\n(Contoso-ASR-Vault)"]
        RecPlan["Recovery Plan\n(Contoso-App-Failover-Plan)"]
    end

    subgraph DRRegion["Disaster Recovery Region: West US (Contoso-App-DR-RG)"]
        VNetDR["VNet-DR (10.1.0.0/16)"]
        
        subgraph DRWebSubnet["Subnet-Web-DR (10.1.1.0/24)"]
            TargetWebVM["Target Web-VM\n(Spun up on failover)"]
        end

        subgraph DRDBSubnet["Subnet-DB-DR (10.1.2.0/24)"]
            TargetDBVM["Target DB-VM\n(Group 1 Startup)"]
        end

        AutoAcct["Azure Automation Account\n(Contoso-ASR-AutoAccount)"]
        ManagedID["System-Assigned Managed Identity"]
        Runbook["PowerShell Runbook\n(Attach-DR-PublicIP.ps1)"]
        DRPIP["Static Public IP\n(Web-VM-DR-PIP)"]
        
        AutoAcct --> ManagedID
        ManagedID -->|RBAC Network Contributor| Runbook
        Runbook -->|Post-Action Cutover| TargetWebVM
        TargetWebVM <--> DRPIP
    end

    User ==>|Active Traffic (Normal Mode)| WebVM
    User -.->|Redirected Traffic (Failover Mode)| DRPIP
    CacheStorage ==>|Continuous Asynchronous Delta Replication| DRRegion
    Vault --> RecPlan
    RecPlan -->|Sequenced Startup & Runbook Execution| DRRegion
```

---

## 2. Component Specifications

### Primary Production Region (`East US`)
* **Resource Group:** `Contoso-App-Prod-RG`
* **Virtual Network:** `VNet-Prod` (`10.0.0.0/16`)
  * `Subnet-Web` (`10.0.1.0/24`) -> Hosts `Web-VM`
  * `Subnet-DB` (`10.0.2.0/24`) -> Hosts `DB-VM`
* **Network Security Group:** `NSG-Prod-Web` (Rules: Allow-HTTP on port 80, Allow-SSH on port 22).
* **Storage:** Standard Managed Disks (`Standard_LRS`) attached to VMs.
* **ASR Buffer:** `asrcache<random>` (Standard General Purpose v2 Storage Account).

### Disaster Recovery Region (`West US`)
* **Resource Group:** `Contoso-App-DR-RG`
* **Virtual Network:** `VNet-DR` (`10.1.0.0/16`) (Ensures no IP overlap with Primary VNet).
  * `Subnet-Web-DR` (`10.1.1.0/24`) -> Target subnet for Web tier.
  * `Subnet-DB-DR` (`10.1.2.0/24`) -> Target subnet for DB tier.
* **Orchestration:** `Contoso-ASR-Vault` (Recovery Services Vault).
* **Automation:** `Contoso-ASR-AutoAccount` (Automation Account) with System-Assigned Managed Identity.
* **Network Cutover:** Static Public IP `Web-VM-DR-PIP` (Standard SKU).

---

## 3. Data Replication & Failover Workflow

1. **Continuous Data Sync:**
   - Disk write changes on `Web-VM` and `DB-VM` are captured by the ASR Mobility extension.
   - Writes are buffered to `asrcache*` in East US and encrypted in transit to West US managed disks.
2. **Disaster Trigger & Failover:**
   - Primary region outage is declared.
   - `Contoso-App-Failover-Plan` is executed in `Contoso-ASR-Vault`.
3. **Sequenced Recovery:**
   - **Group 1:** `DB-VM` target virtual machine is created and booted in `Subnet-DB-DR`.
   - **Group 2:** `Web-VM` target virtual machine is created and booted in `Subnet-Web-DR`.
4. **Post-Action Automation:**
   - Group 2 triggers the PowerShell runbook `Attach-DR-PublicIP.ps1`.
   - The runbook authenticates via Managed Identity and binds `Web-VM-DR-PIP` to the target Web VM network interface.
   - Application web traffic is immediately restored on the secondary region IP.
