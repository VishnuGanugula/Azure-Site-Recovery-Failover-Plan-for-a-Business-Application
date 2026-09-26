# 🛠️ Azure Services & AZ-104 Certification Domain Mapping

This document maps all Azure services and configurations used in this project directly to the official **Microsoft Certified: Azure Administrator Associate (AZ-104)** exam syllabus.

---

## 🏛️ AZ-104 Domain 1: Manage Azure Identities and Governance (15–20%)

### 1. System-Assigned Managed Identity
- **Service:** Azure Automation Identity.
- **AZ-104 Skill:** Configure managed identities for Azure resources.
- **Implementation:** Enables `Contoso-ASR-AutoAccount` to authenticate securely to Azure Resource Manager without embedding secret keys or passwords in PowerShell runbook scripts.

### 2. Role-Based Access Control (RBAC)
- **Service:** Azure IAM.
- **AZ-104 Skill:** Assign RBAC roles to users, groups, and managed identities.
- **Implementation:** Assigned the **Network Contributor** role on target Resource Group `Contoso-App-DR-RG` to the Automation Account's Principal ID.

### 3. Resource Groups & Governance
- **Service:** Azure Resource Manager (ARM).
- **AZ-104 Skill:** Manage resource groups and apply resource tagging.
- **Implementation:** Primary environment isolated in `Contoso-App-Prod-RG` (`eastus`); DR environment isolated in `Contoso-App-DR-RG` (`westus`).

---

## 💾 AZ-104 Domain 2: Implement and Manage Storage (15–20%)

### 1. Azure Storage Accounts (Blob / Standard LRS)
- **Service:** Azure Storage.
- **AZ-104 Skill:** Configure storage accounts, access tiers, and replication.
- **Implementation:** Deployed `asrcachestorage*` in the Primary region (`eastus`) as an intermediary staging buffer for ASR disk write deltas before asynchronous transfer to West US.

### 2. Managed Disks
- **Service:** Azure Disks (Standard SSD / LRS).
- **AZ-104 Skill:** Manage virtual machine storage disks and snapshots.
- **Implementation:** VMs in East US use Standard LRS managed OS disks, which are continuously snapshotted and replicated to target managed disks in West US.

---

## 🖥️ AZ-104 Domain 3: Deploy and Manage Azure Compute Resources (20–25%)

### 1. Virtual Machines (Linux / Ubuntu 22.04 LTS)
- **Service:** Azure Compute (IaaS).
- **AZ-104 Skill:** Provision and configure Virtual Machines using Azure CLI / ARM templates.
- **Implementation:** Deployed `Web-VM` and `DB-VM` size `Standard_B2s` in primary VNet.

### 2. Custom Script Extension / Cloud-Init
- **Service:** Azure VM Extensions.
- **AZ-104 Skill:** Automate VM configuration during provisioning.
- **Implementation:** Utilized `cloud-init-primary.txt` to automatically update packages, install Nginx, enable the system service, and deploy the production status web interface.

### 3. Azure Automation & PowerShell Runbooks
- **Service:** Azure Automation.
- **AZ-104 Skill:** Implement Automation runbooks and process automation.
- **Implementation:** Created PowerShell 7.2 runbook `Attach-DR-PublicIP.ps1` to reattach target Static Public IP to the spun-up Web VM NIC during failover.

---

## 🌐 AZ-104 Domain 4: Configure and Manage Virtual Networking (20–25%)

### 1. Virtual Networks (VNets) & Subnets
- **Service:** Azure Virtual Network.
- **AZ-104 Skill:** Plan and configure VNets, subnets, and IP addressing schemes.
- **Implementation:** 
  - Primary VNet: `VNet-Prod` (`10.0.0.0/16`) with `Subnet-Web` (`10.0.1.0/24`) and `Subnet-DB` (`10.0.2.0/24`).
  - Target DR VNet: `VNet-DR` (`10.1.0.0/16`) with `Subnet-Web-DR` (`10.1.1.0/24`) and `Subnet-DB-DR` (`10.1.2.0/24`).

### 2. Network Security Groups (NSGs)
- **Service:** Azure NSG.
- **AZ-104 Skill:** Create and configure Network Security Group rules.
- **Implementation:** Provisioned `NSG-Prod-Web` and `NSG-DR-Web` allowing inbound HTTP (Port 80) and SSH (Port 22) traffic.

### 3. Public IP Addresses & Network Interfaces (NICs)
- **Service:** Azure Network Resources.
- **AZ-104 Skill:** Configure public IP addresses and network interfaces.
- **Implementation:** Pre-created static Standard SKU Public IP `Web-VM-DR-PIP` in West US for dynamic post-failover attachment.

---

## 📊 AZ-104 Domain 5: Monitor and Maintain Azure Resources (10–15%)

### 1. Recovery Services Vault & Azure Site Recovery (ASR)
- **Service:** Azure Backup & Site Recovery.
- **AZ-104 Skill:** Implement site recovery, backup policies, and disaster recovery.
- **Implementation:** Configured `Contoso-ASR-Vault` in `westus` for continuous VM disk replication, network mapping, and ordered Recovery Plan execution.

### 2. Azure Monitor & ASR Job History
- **Service:** Azure Monitor.
- **AZ-104 Skill:** Monitor resources and review job execution logs.
- **Implementation:** Tracked failover execution jobs, RTO timing logs, and disk replication health status.
