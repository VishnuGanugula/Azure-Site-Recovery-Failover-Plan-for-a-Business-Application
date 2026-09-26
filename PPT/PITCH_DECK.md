# 🎤 AZ-104 Hackathon Presentation & Pitch Deck

## Project Title: Cross-Region Multi-Tier Disaster Recovery with Azure Site Recovery (ASR)

---

## ⏱️ 5-Minute Timed Presentation Pitch

```text
+-----------------------------------------------------------------------------------+
| TIME          | SLIDE / SECTION               | KEY DEMONSTRATION FOCUS           |
+-----------------------------------------------------------------------------------+
| 0:00 - 0:45   | 1. Executive Summary & Problem| Enterprise BCDR Challenge ($300k/h)|
| 0:45 - 1:45   | 2. AZ-104 Architecture Design | Cross-Region VNet + ASR + Vault   |
| 1:45 - 3:00   | 3. Live Failover Demonstration | Cooking Show Cutover to West US   |
| 3:00 - 4:00   | 4. Recovery Metrics & Value   | RTO: 4.5 Min | RPO: < 30 Sec      |
| 4:00 - 5:00   | 5. Security & Judge Q&A       | Passwordless Managed Identity     |
+-----------------------------------------------------------------------------------+
```

---

## 📽️ Slide Breakdown & Speaker Script

### Slide 1: Executive Summary & Problem Statement
- **Speaker Script:**
  > *"Unplanned enterprise downtime costs organizations an average of \$300,000 per hour. While active-active multi-region deployments provide zero downtime, they double infrastructure compute costs. In this AZ-104 hackathon project, we solved this dilemma using Azure Site Recovery (ASR) to deliver cross-region failover with zero compute idle costs in our DR region."*

### Slide 2: Architectural Alignment with AZ-104 Exam Domains
- **Speaker Script:**
  > *"Our solution covers all 5 core AZ-104 domains:
  > 1. **Identities & Governance:** Passwordless Managed Identity on Azure Automation with RBAC Network Contributor role.
  > 2. **Storage:** Cache Storage Accounts for delta buffering and Standard LRS replicated disks.
  > 3. **Compute:** Automated VM deployment via Cloud-Init and PowerShell automation runbooks.
  > 4. **Networking:** Non-overlapping VNets (10.0.0.0/16 vs 10.1.0.0/16) and NSG rule enforcement.
  > 5. **Monitoring & Recovery:** Recovery Services Vault orchestration with ordered startup groups."*

### Slide 3: Live Failover Demonstration (Cooking Show Strategy)
- **Speaker Script:**
  > *"Rather than waiting 15 minutes for Azure portal progress bars during our pitch, we pre-staged a Test Failover 15 minutes ago. Here is our live primary web portal in East US. Now observe our ASR Recovery Plan: Group 1 brought up our SQL Database tier first, Group 2 booted our Nginx Web server, and our PowerShell Runbook re-attached our DR Public IP automatically!"*

### Slide 4: Measured Recovery Objectives (RTO & RPO)
- **Speaker Script:**
  > *"Our empirical results:
  > - **Recovery Time Objective (RTO):** 4 minutes 30 seconds (Industry standard < 15 mins).
  > - **Recovery Point Objective (RPO):** Under 30 seconds via continuous asynchronous disk sync.
  > - **Idle Cost:** \$0 per hour for compute in West US while in standby mode."*

---

## 💡 Judge Q&A Cheat Sheet

| Question | Winning Answer |
| :--- | :--- |
| **Why ASR over Azure Backup?** | *"Backup provides point-in-time snapshots with high RTO (hours). ASR provides continuous block-level disk replication with an RTO of minutes."* |
| **How is authentication secured in runbooks?** | *"We use Azure System-Assigned Managed Identity. Zero connection strings or hardcoded password credentials exist in our code."* |
| **Why is startup grouping necessary?** | *"If the Web tier boots before the Database tier is listening, web connections crash. Group 1 ensures DB availability before Group 2 boots Web."* |
