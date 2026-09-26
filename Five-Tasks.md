# 🎯 Five Core Hands-On Tasks (AZ-104 Execution Steps)

To complete the hackathon project successfully, execute these 5 core tasks in sequence.

---

## Task 1: Provision Primary & Disaster Recovery Infrastructure (CLI Automation)
* **Domain Alignment:** AZ-104 Domain 3 (Compute) & Domain 4 (Networking).
* **Objective:** Deploy two isolated environments in paired regions (`East US` and `West US`) using Azure CLI.
* **Execution Steps:**
  1. Open Azure Cloud Shell (`bash`).
  2. Execute `scripts/1-deploy-base-infra.sh` to create `Contoso-App-Prod-RG`, `VNet-Prod` (`10.0.0.0/16`), `NSG-Prod-Web`, `Web-VM`, and `DB-VM`.
  3. Execute `scripts/2-deploy-dr-infra.sh` to create `Contoso-App-DR-RG`, `VNet-DR` (`10.1.0.0/16`), `NSG-DR-Web`, `Web-VM-DR-PIP`, `asrcachestorage*`, and `Contoso-ASR-Vault`.
* **Verification:** Confirm `Web-VM` Public IP opens the Primary Nginx production landing page.

---

## Task 2: Configure Network Mapping & Enable Site Recovery Protection
* **Domain Alignment:** AZ-104 Domain 2 (Storage) & Domain 5 (Monitoring & Backup).
* **Objective:** Establish replication infrastructure in the Recovery Services Vault.
* **Execution Steps:**
  1. In `Contoso-ASR-Vault` (`westus`), navigate to **Site Recovery infrastructure** > **Network Mapping**.
  2. Map `VNet-Prod` (`eastus`) to `VNet-DR` (`westus`).
  3. Go to `Contoso-App-Prod-RG` > `Web-VM` > **Disaster recovery**.
  4. Select Target Region `West US`, Target Resource Group `Contoso-App-DR-RG`, Target Network `VNet-DR`, Target Subnet `Subnet-Web-DR`, and Cache Storage Account `asrcache*`.
  5. Start replication for `Web-VM` and `DB-VM` (`Subnet-DB-DR`).
* **Verification:** Confirm both VMs show **Healthy (Protected)** in `Contoso-ASR-Vault` > **Replicated Items**.

---

## Task 3: Provision Automation Account, Managed Identity & RBAC
* **Domain Alignment:** AZ-104 Domain 1 (Identity & Governance) & Domain 3 (Compute).
* **Objective:** Establish secure passwordless runbook execution capability.
* **Execution Steps:**
  1. Verify `Contoso-ASR-AutoAccount` has System-Assigned Managed Identity enabled.
  2. Assign the **Network Contributor** RBAC role on `Contoso-App-DR-RG` to the Managed Identity Principal ID.
  3. In **Automation Account** > **Runbooks**, create a PowerShell 7.2 Runbook named `Attach-DR-PublicIP`.
  4. Copy code from `scripts/Attach-DR-PublicIP.ps1` and click **Publish**.
* **Verification:** Run a test execution of the runbook in Automation Account Test Pane.

---

## Task 4: Construct Sequenced Recovery Plan with Post-Action Script
* **Domain Alignment:** AZ-104 Domain 5 (Monitoring & Backup).
* **Objective:** Create an ordered failover recovery sequence.
* **Execution Steps:**
  1. In `Contoso-ASR-Vault`, click **Recovery Plans** > **+ Recovery Plan**. Name: `Contoso-App-Failover-Plan`.
  2. Move `DB-VM` to **Group 1** (Database starts first).
  3. Move `Web-VM` to **Group 2** (Web Server starts after DB is running).
  4. Right-click **Group 2** > **Add post-action** > Script -> Select `Contoso-ASR-AutoAccount` and runbook `Attach-DR-PublicIP`.
* **Verification:** Review Recovery Plan outline to ensure DB precedes Web and script is attached to Group 2.

---

## Task 5: Execute Test Failover & Validate RTO / RPO Cutover
* **Domain Alignment:** AZ-104 Domain 4 (Networking) & Domain 5 (Monitoring & Backup).
* **Objective:** Perform zero-impact disaster recovery verification.
* **Execution Steps:**
  1. Open `Contoso-App-Failover-Plan` and click **Test Failover**.
  2. Select target network `VNet-DR`.
  3. Monitor job execution steps: VM creation, startup order, and runbook execution.
  4. Copy the static DR Public IP (`Web-VM-DR-PIP`) and paste into a new browser tab.
* **Verification:** Confirm RTO timer is under 5 minutes and the web application is live in West US!
