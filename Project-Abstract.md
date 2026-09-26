# 📑 Project Abstract: Azure Site Recovery (ASR) Failover Plan

## 1. Executive Summary
In modern enterprise cloud computing, system availability and data resilience are critical operational objectives. Unplanned outages caused by regional infrastructure failures, natural disasters, or connectivity disruptions can result in severe financial loss and reputational damage.

This project delivers an automated, cross-region **Disaster Recovery (DR) solution** using **Azure Site Recovery (ASR)** for a 2-Tier Business Application (Nginx Web Tier + Database Tier). Designed for the **AZ-104 Azure Administrator Hackathon**, the project demonstrates how organizations can achieve near-zero Recovery Point Objectives (RPO) and low Recovery Time Objectives (RTO) while eliminating idle compute expenses in the target DR region.

---

## 2. Key Objectives & Business Motivation
- **Automated Cross-Region Resilience:** Replicate virtual machines from a primary region (`East US`) to a secondary paired region (`West US`).
- **Sequenced Recovery Orchestration:** Ensure dependent application tiers (Database before Web) boot in the correct logical sequence using ASR Recovery Plans.
- **Dynamic Network Cutover:** Automate target Public IP attachment using an Azure Automation Account with System-Assigned Managed Identity and Role-Based Access Control (RBAC).
- **Cost Optimization:** Maintain standby DR compute costs at **\$0/hour** by replicating disk storage deltas without running idle VMs in the DR region.

---

## 3. Targeted Metrics
- **Recovery Time Objective (RTO):** `< 10 Minutes` (Empirically achieved: **4 minutes 30 seconds**).
- **Recovery Point Objective (RPO):** `< 30 Seconds` (Continuous asynchronous disk replication).
- **Security Compliance:** **100% Passwordless** runbook authentication using Azure Entra ID / Managed Identity.
- **AZ-104 Domain Coverage:** 100% alignment across all 5 Azure Administrator certification domains.
