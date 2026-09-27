# 🛠️ Azure Services & AZ-104 Certification Domain Mapping

This document maps all Azure services, CLI commands, and architectural components utilized in the **SpendWise 3-Tier Disaster Recovery Project** directly to the official **Microsoft Certified: Azure Administrator Associate (AZ-104)** exam syllabus.

---

## 🏛️ AZ-104 Domain 1: Manage Azure Identities and Governance (15–20%)

### 1. Azure Resource Manager (ARM) & Governance
- **Services:** Resource Groups, Management Locks, Tags.
- **AZ-104 Skill:** Manage resource groups and organize Azure resources.
- **Project Implementation:** Primary production resources isolated in `RG-ASR-24CC3046` (Central India); disaster recovery resources isolated in `RG-ASR-24CC3046-DR` (India South Central).

### 2. Role-Based Access Control (RBAC) & Service Principals
- **Services:** Azure IAM, Role Assignments.
- **AZ-104 Skill:** Configure access to Azure resources using RBAC roles.
- **Project Implementation:** Assigned **Contributor** and **Network Contributor** permissions for vault and recovery plan execution across resource groups.

---

## 💾 AZ-104 Domain 2: Implement and Manage Storage (15–20%)

### 1. Azure Managed Disks & Storage Accounts
- **Services:** Azure Premium LRS / Standard LRS Managed Disks, Storage Accounts.
- **AZ-104 Skill:** Manage storage accounts and VM disk storage.
- **Project Implementation:** OS managed disks attached to `VM-DB`, `VM-APP`, and `VM-WEB` are continuously snapshotted and replicated to target replica disks in India South Central using ASR cache storage accounts for delta write buffering.

---

## 🖥️ AZ-104 Domain 3: Deploy and Manage Azure Compute Resources (20–25%)

### 1. Virtual Machine Provisioning & Linux Guest Management
- **Services:** Azure Compute (IaaS), Ubuntu Linux 22.04 LTS.
- **AZ-104 Skill:** Configure VM sizes, availability, and guest operating system settings.
- **Project Implementation:** Provisioned three dedicated Linux VM tiers (`VM-DB`, `VM-APP`, `VM-WEB`).

### 2. Azure VM Run Command (`az vm run-command`)
- **Services:** Azure Virtual Machine Management Extensions.
- **AZ-104 Skill:** Post-deployment management, scripting, and guest OS troubleshooting.
- **Project Implementation:** Used `az vm run-command invoke` with `RunShellScript` to:
  1. Inspect running guest Linux kernel versions (`uname -r`).
  2. Install supported Azure 5.15 Linux kernel (`linux-image-5.15.0-1003-azure`).
  3. Validate TCP socket connectivity on ports 5432 and 5000 (`/dev/tcp` bash sockets).
  4. Perform in-guest configuration edits to `/opt/spendwise/app.py` and `/etc/postgresql/14/main/pg_hba.conf`.

---

## 🌐 AZ-104 Domain 4: Configure and Manage Virtual Networking (20–25%)

### 1. Virtual Networks (VNets), Subnets & Network Isolation
- **Services:** Azure Virtual Network, Subnet configuration.
- **AZ-104 Skill:** Configure VNet-to-VNet connections, IP addressing, and isolated test networks.
- **Project Implementation:** Target test VMs were instantiated inside isolated virtual network `VNET-ASR-TEST` on subnet `SUBNET-TEST` (`10.30.1.0/24`), ensuring test failover operations do not interfere with production network routes.

### 2. Network Interfaces (NICs) & Private IP Management
- **Services:** Azure Network Interfaces.
- **AZ-104 Skill:** Configure NICs and static/dynamic IP addressing.
- **Project Implementation:** Verified NIC mappings (`VM-DBVMNic-test`, `VM-APPVMNic-test`, `VM-WEBVMNic-test`) and validated assigned IP addresses (`10.30.1.4`, `10.30.1.5`, `10.30.1.6`).

---

## 📊 AZ-104 Domain 5: Monitor and Maintain Azure Resources (10–15%)

### 1. Recovery Services Vault & Azure Site Recovery (ASR)
- **Services:** Azure Site Recovery, Recovery Services Vault.
- **AZ-104 Skill:** Implement site recovery, backup policies, and disaster recovery.
- **Project Implementation:**
  - Configured vault `RSV-ASR-24CC3046`.
  - Defined fabrics (`FABRIC-CENTRALINDIA`, `FABRIC-DR-ISC`) and containers (`PC-SOURCE-CENTRALINDIA`, `PC-DR-ISC`).
  - Implemented replication policy `POLICY-A2A-SPENDWISE`.
  - Constructed ordered 3-tier Recovery Plan `RP-3TIER-APP`.

### 2. ARM REST API Integration (`az rest`)
- **Services:** Azure Resource Manager REST API.
- **AZ-104 Skill:** Automate Azure management operations via ARM APIs when CLI commands are version-restricted.
- **Project Implementation:** Used `az rest` to execute `testFailover` against `https://management.azure.com/.../replicationRecoveryPlans/RP-3TIER-APP/testFailover?api-version=2025-02-01`.

### 3. ASR Job Monitoring & Execution Validation
- **Services:** Azure Site Recovery Job Engine & Azure Monitor.
- **AZ-104 Skill:** Track backup/recovery jobs and evaluate RTO/RPO metrics.
- **Project Implementation:** Monitored job `7df5bc18-4a2e-40ff-83da-1b21f16ea647`, verifying successful execution in 5 minutes 24 seconds.
