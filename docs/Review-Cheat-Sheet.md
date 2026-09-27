# 📋 Review-Day Command Execution Cheat Sheet

Run these exact commands in this sequence when demonstrating or presenting the project to reviewers and judges.

---

## 1. Verify Protected Items & Replication Health
```bash
az site-recovery protected-item list -g RG-ASR-24CC3046 --vault-name RSV-ASR-24CC3046 --fabric-name FABRIC-CENTRALINDIA --protection-container PC-SOURCE-CENTRALINDIA --query "[].{VM:properties.friendlyName,State:properties.protectionState,Health:properties.replicationHealth}" -o table
```
* **Expected Output:**
  ```text
  VM        State      Health
  ------    ---------  --------
  VM-WEB    Protected  Normal
  VM-APP    Protected  Normal
  VM-DB     Protected  Normal
  ```

---

## 2. Inspect 3-Tier Sequenced Recovery Plan (`RP-3TIER-APP`)
```bash
az site-recovery recovery-plan show -g RG-ASR-24CC3046 --vault-name RSV-ASR-24CC3046 --name RP-3TIER-APP --query "properties.groups[].{Type:groupType,VMs:replicationProtectedItems[].id}" -o json
```
* **Expected Output:** JSON output displaying 3 distinct `Boot` groups containing DB, APP, and WEB items.

---

## 3. Query Latest Test Failover Job Status
```bash
az site-recovery job list -g RG-ASR-24CC3046 --vault-name RSV-ASR-24CC3046 --query "[?properties.scenarioName=='TestFailover'] | sort_by(@,&properties.startTime) | [-1].{Name:name,Scenario:properties.scenarioName,State:properties.state,Start:properties.startTime,End:properties.endTime,Error:properties.error}" -o table
```
* **Expected Output:**
  `Job 7df5bc18-4a2e-40ff-83da-1b21f16ea647 | State: Succeeded | Error: null`

---

## 4. List Active Test-Failover VMs in DR Region
```bash
az vm list -g RG-ASR-24CC3046-DR -o table
```
* **Expected Output:** Displays `VM-DB-test`, `VM-APP-test`, and `VM-WEB-test`.

---

## 5. Verify APP → DB TCP Port Connectivity (Port 5432)
```bash
az vm run-command invoke -g RG-ASR-24CC3046-DR -n VM-APP-test --command-id RunShellScript --scripts "timeout 5 bash -c '</dev/tcp/10.30.1.4/5432' && echo DB_PORT_5432_OK || echo DB_PORT_5432_FAILED"
```
* **Expected Output:** `DB_PORT_5432_OK`

---

## 6. Verify WEB → APP TCP Port Connectivity (Port 5000)
```bash
az vm run-command invoke -g RG-ASR-24CC3046-DR -n VM-WEB-test --command-id RunShellScript --scripts "timeout 5 bash -c '</dev/tcp/10.30.1.5/5000' && echo APP_PORT_5000_OK || echo APP_PORT_5000_FAILED"
```
* **Expected Output:** `APP_PORT_5000_OK`

---

## 7. Validate End-to-End Application Health Endpoint
```bash
az vm run-command invoke -g RG-ASR-24CC3046-DR -n VM-WEB-test --command-id RunShellScript --scripts "curl -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code}\n' http://10.30.1.5:5000/health"
```
* **Expected Output:**
  ```json
  {"application":"SpendWise","database":"connected","status":"healthy"}
  HTTP_STATUS=200
  ```

---

## 8. Final Project Narrative for Presentation

When presenting to judges:
> *"Our project demonstrates complete cross-region business continuity for the **SpendWise 3-Tier Enterprise Application** from **Central India** to **India South Central**.
> Rather than simple VM creation, we engineered a full 3-tier recovery workflow:
> 1. Production VMs (`VM-DB`, `VM-APP`, `VM-WEB`) continuously sync to Recovery Services Vault `RSV-ASR-24CC3046`.
> 2. Recovery Plan `RP-3TIER-APP` orchestrates sequenced boot startup (DB → APP → WEB).
> 3. ARM REST API executed test failover into isolated network `VNET-ASR-TEST` in **5 minutes 24 seconds**.
> 4. Post-failover diagnostics reconfigured `app.py` target IPs and PostgreSQL `pg_hba.conf` access rules.
> 5. End-to-end verification confirmed `HTTP 200 OK` with database status `connected`."*
