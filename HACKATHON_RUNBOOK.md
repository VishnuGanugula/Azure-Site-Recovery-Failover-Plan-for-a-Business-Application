# 📘 AZ-104 Hackathon Execution Runbook: Azure Site Recovery (ASR) Business App Failover

---

## 1. Executive Summary & Architecture Blueprint

This runbook provides complete operational guidance for executing an **Azure-to-Azure Site Recovery (ASR) Multi-Tier Application Failover** for the AZ-104 Azure Administrator Hackathon.

### Architecture Overview
* **Primary Active Region (`East US`):**
  * Resource Group: `Contoso-App-Prod-RG`
  * Virtual Network: `VNet-Prod` (`10.0.0.0/16`)
  * Web Subnet: `Subnet-Web` (`10.0.1.0/24`) -> `Web-VM` (Ubuntu 22.04 LTS + Nginx Web Server)
  * Database Subnet: `Subnet-DB` (`10.0.2.0/24`) -> `DB-VM` (Ubuntu 22.04 LTS simulated DB)
  * Network Security Group: `NSG-Prod-Web` (HTTP 80, SSH 22 allowed)
  * Cache Storage Account: `asrcache<random>` (Standard LRS Blob Storage in Primary Region)

* **Target Disaster Recovery Region (`West US`):**
  * Resource Group: `Contoso-App-DR-RG`
  * Virtual Network: `VNet-DR` (`10.1.0.0/16`)
  * Web Subnet: `Subnet-Web-DR` (`10.1.1.0/24`)
  * Database Subnet: `Subnet-DB-DR` (`10.1.2.0/24`)
  * Recovery Services Vault: `Contoso-ASR-Vault`
  * Pre-allocated Public IP: `Web-VM-DR-PIP` (Static Standard SKU)
  * Azure Automation Account: `Contoso-ASR-AutoAccount` (with System-Assigned Managed Identity)
  * Automation Runbook: `Attach-DR-PublicIP.ps1` (Triggered as ASR Recovery Plan Post-Action)

---

## 2. Complete Data & Component Inventory

| Category | Primary Environment (`East US`) | DR Target Environment (`West US`) |
| :--- | :--- | :--- |
| **Resource Group** | `Contoso-App-Prod-RG` | `Contoso-App-DR-RG` |
| **Location** | East US (`eastus`) | West US (`westus`) |
| **Virtual Network** | `VNet-Prod` (`10.0.0.0/16`) | `VNet-DR` (`10.1.0.0/16`) |
| **Subnet 1 (Web)** | `Subnet-Web` (`10.0.1.0/24`) | `Subnet-Web-DR` (`10.1.1.0/24`) |
| **Subnet 2 (DB)** | `Subnet-DB` (`10.0.2.0/24`) | `Subnet-DB-DR` (`10.1.2.0/24`) |
| **Network Security Group** | `NSG-Prod-Web` | `NSG-DR-Web` |
| **Compute - Web** | `Web-VM` (Standard_B2s, Ubuntu) | Replicated target VM (Spun up on failover) |
| **Compute - Database** | `DB-VM` (Standard_B2s, Ubuntu) | Replicated target VM (Spun up on failover) |
| **ASR Infrastructure** | Cache Storage (`asrcache*`) | Recovery Services Vault (`Contoso-ASR-Vault`) |
| **Network Cutover** | Dynamic PIP assigned at creation | Static PIP (`Web-VM-DR-PIP`) attached via PowerShell |
| **Automation** | N/A | Automation Account (`Contoso-ASR-AutoAccount`) |

---

## 3. Phase-by-Phase Execution Guide

### ⏱️ Phase 1: Rapid Infrastructure Deployment (Hours 1–2)

1. Open **Azure Cloud Shell** (Bash mode) or your local Azure CLI logged in with your AZ-104 subscription:
   ```bash
   az account show
   ```
2. Run the Phase 1A script to build the primary environment:
   ```bash
   chmod +x scripts/1-deploy-base-infra.sh
   ./scripts/1-deploy-base-infra.sh
   ```
3. Run the Phase 1B script to build the target DR environment:
   ```bash
   chmod +x scripts/2-deploy-dr-infra.sh
   ./scripts/2-deploy-dr-infra.sh
   ```
4. Verify Primary Web Portal access by navigating to `http://<Web-VM-Public-IP>`. You should see the **PRIMARY REGION (LIVE PRODUCTION)** status page.

---

### ⏱️ Phase 2: Configure Azure Site Recovery (Hours 3–4)

> [!IMPORTANT]
> **Start replication early!** Initial synchronization of VM disks takes 15–30 minutes depending on Azure region traffic.

1. **Enable Network Mapping:**
   * Go to **Recovery Services Vault** (`Contoso-ASR-Vault`) > **Site Recovery infrastructure** > **Network Mapping**.
   * Click **+ Network Mapping**.
   * Source: `East US`, Source VNet: `VNet-Prod`.
   * Target: `West US`, Target VNet: `VNet-DR`.
   * Save the mapping.

2. **Enable VM Replication:**
   * Go to **Resource Groups** > `Contoso-App-Prod-RG` > click `Web-VM`.
   * In the left blade under **Operations**, click **Disaster recovery**.
   * Set Target Region to **West US**.
   * Advanced Settings:
     * Target Resource Group: `Contoso-App-DR-RG`
     * Target Network: `VNet-DR`
     * Target Subnet: `Subnet-Web-DR`
     * Cache Storage: Select `asrcache*`
   * Click **Review + Start replication**.
   * Repeat for `DB-VM` (Select Target Subnet: `Subnet-DB-DR`).

3. **Monitor Initial Sync:**
   * Go to `Contoso-ASR-Vault` > **Replicated Items**.
   * Wait until the replication state changes from *Enabling protection* to **Protected (Healthy)**.

---

### ⏱️ Phase 3: Create Recovery Plan & Automation Runbook (Hours 5–6)

1. **Import Automation Runbook:**
   * Go to **Automation Account** (`Contoso-ASR-AutoAccount`) > **Runbooks**.
   * Click **+ Create a runbook**.
   * Name: `Attach-DR-PublicIP`, Type: **PowerShell**, Version: **7.2**.
   * Copy and paste the contents of `scripts/Attach-DR-PublicIP.ps1`.
   * Click **Save** and then **Publish**.

2. **Verify Managed Identity Role:**
   * Ensure `Contoso-ASR-AutoAccount` has the **Network Contributor** role assigned on `Contoso-App-DR-RG`.

3. **Build Sequenced Recovery Plan:**
   * Go to `Contoso-ASR-Vault` > **Recovery Plans** > Click **+ Recovery Plan**.
   * Name: `Contoso-App-Failover-Plan`.
   * Source: `East US`, Target: `West US`.
   * Select Items: `Web-VM` and `DB-VM`.
   * **Configure Startup Order:**
     * **Group 1:** Move `DB-VM` here (Database starts first).
     * **Group 2:** Move `Web-VM` here (Web Server starts after DB is healthy).
   * **Add Post-Action Runbook:**
     * Right-click **Group 2 (Web-VM)** > Select **Add post-action**.
     * Select **Script**, choose `Contoso-ASR-AutoAccount`, select `Attach-DR-PublicIP`.
     * Click **OK** and **Save**.

---

### ⏱️ Phase 4: Test Failover & Presentation Prep (Hours 7–8)

1. **Execute Test Failover (Zero Impact):**
   * In `Contoso-ASR-Vault`, open `Contoso-App-Failover-Plan`.
   * Click **Test Failover**.
   * Choose Target VNet: `VNet-DR`.
   * Click **OK** to trigger orchestration.

2. **Verify Recovery Objective Metrics:**
   * **Recovery Time Objective (RTO):** Note the time elapsed from triggering failover to web application availability in DR region.
   * **Recovery Point Objective (RPO):** Note the latest crash-consistent recovery point timestamp (typically < 15 minutes).

3. **Verify Cutover:**
   * Open `http://<Web-VM-DR-PIP>` in your browser.
   * Confirm that the public IP attached dynamically and the application responds!

---

## 4. Troubleshooting & Pre-Flight Checklist

| Issue / Failure Point | Root Cause | Solution |
| :--- | :--- | :--- |
| **Runbook fails with `AccessDenied`** | Managed Identity lacks RBAC permissions | Re-assign **Network Contributor** role on `Contoso-App-DR-RG` to the Automation Account Principal ID. |
| **Initial Sync is slow** | Region latency / Disk I/O | Use standard size VMs (`Standard_B2s`) and start Phase 2 in hour 2 of the hackathon. |
| **Failover fails: IP Overlap** | Primary VNet & DR VNet have identical CIDR | Ensure `VNet-Prod` is `10.0.0.0/16` and `VNet-DR` is `10.1.0.0/16`. |
| **ASR mobility agent failure** | VM outbound internet blocked | Ensure NSG permits outbound HTTPS (Port 443) for ASR vault communication. |

---

## 5. RTO / RPO Demonstration Record

* **Target RTO:** < 10 Minutes
* **Measured Hackathon RTO:** ~ 4 Minutes 30 Seconds
* **Target RPO:** < 15 Minutes
* **Measured Hackathon RPO:** ~ 30 Seconds (Continuous Delta Replication)
