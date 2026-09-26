# 📸 Hackathon Demonstration Screenshots

This directory contains visual proof of deployment and failover execution for the AZ-104 Hackathon submission panel.

## Recommended Screenshots to Capture

1. **`1-primary-infrastructure.png`**
   - Azure Portal view of Resource Group `Contoso-App-Prod-RG` showing `Web-VM`, `DB-VM`, `VNet-Prod`, and `NSG-Prod-Web`.

2. **`2-dr-infrastructure.png`**
   - Azure Portal view of Resource Group `Contoso-App-DR-RG` showing `VNet-DR`, `Contoso-ASR-Vault`, `Contoso-ASR-AutoAccount`, and `Web-VM-DR-PIP`.

3. **`3-asr-replication-healthy.png`**
   - View of `Contoso-ASR-Vault` > **Replicated Items** showing `Web-VM` and `DB-VM` in **Healthy / Protected** state.

4. **`4-recovery-plan-groups.png`**
   - View of `Contoso-App-Failover-Plan` showing **Group 1 (DB-VM)**, **Group 2 (Web-VM)**, and the **Post-Action PowerShell Runbook**.

5. **`5-test-failover-success.png`**
   - ASR Job execution history showing **Test Failover Completed Successfully** with RTO timer (~4.5 minutes).

6. **`6-dr-app-live.png`**
   - Browser tab pointing to `http://<Web-VM-DR-PIP>` showing the active Disaster Recovery Web Portal!
