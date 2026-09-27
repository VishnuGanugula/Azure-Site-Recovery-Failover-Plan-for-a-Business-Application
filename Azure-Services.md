# 🛠️ Azure Services & AZ-104 Certification Domain Mapping

> [!NOTE]
> The complete AZ-104 domain mapping documentation is located in [`docs/Azure-Services.md`](file:///Users/vishnuganugula/KLU/3.1/Azure/docs/Azure-Services.md).

This document maps all Azure services, CLI commands, and architectural components utilized in the **SpendWise 3-Tier Disaster Recovery Project** directly to the official **Microsoft Certified: Azure Administrator Associate (AZ-104)** exam syllabus.

---

## 🏛️ AZ-104 Domain Breakdown

| AZ-104 Exam Domain | Domain Weight | Key Azure Services Used | Project Implementation Summary |
| :--- | :--- | :--- | :--- |
| **Domain 1: Manage Azure Identities and Governance** | 15–20% | ARM Resource Groups, IAM RBAC, Tagging | `RG-ASR-24CC3046` (Central India) & `RG-ASR-24CC3046-DR` (India South Central) governance. |
| **Domain 2: Implement and Manage Storage** | 15–20% | Standard LRS Managed Disks, Storage Accounts | ASR continuous disk delta replication & cache storage staging buffers. |
| **Domain 3: Deploy and Manage Azure Compute Resources** | 20–25% | Linux VMs (`Ubuntu 22.04 LTS`), VM Run Command | 3-Tier VM deployment (`VM-DB`, `VM-APP`, `VM-WEB`), guest kernel switch (`5.15.0-1003-azure`), in-guest config remediation. |
| **Domain 4: Configure and Manage Virtual Networking** | 20–25% | VNets, Subnets, NICs, Isolated Test VNet | Test failover network isolation in `VNET-ASR-TEST` / `SUBNET-TEST` (`10.30.1.0/24`). |
| **Domain 5: Monitor and Maintain Azure Resources** | 10–15% | Recovery Services Vault, ASR, ARM REST API | `RSV-ASR-24CC3046` vault, ordered Recovery Plan `RP-3TIER-APP`, direct REST API execution & job monitoring. |
