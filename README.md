# backend-systems

The **simulated source systems** of the
[AI Intelligence Domain demo](https://github.com/azure-intelligence-domain/ai-intelligence-domain):
Salesforce, SAP, the warehouse and the 3PL partner. Each keeps its own data in its own model and
is reachable **only through its System API** (ADR 0007).

| System | Store | System API | Status |
|---|---|---|---|
| Salesforce (system of record for orders) | Cosmos DB serverless `cosmos-intplat-salesforce` | [system-api-salesforce](https://github.com/azure-intelligence-domain/system-api-salesforce) | ✅ |
| SAP | — | system-api-sap | ⏳ step 6 |
| Warehouse (WMS) | — | system-api-wms | ⏳ step 6 |
| 3PL partner | — | system-api-3pl | ⏳ step 6 |

```mermaid
flowchart LR
    api["Salesforce System API<br/>runtime identity"] -- "Entra ID · Cosmos DB Data Contributor" --> sf[("cosmos-intplat-salesforce<br/>Order · AutoNumber")]
    other["Anyone else"] -. "no keys, no role: no access" .-x sf
```

- Entra ID only: key authentication is disabled; only the System API's runtime identity has a
  data role.
- Salesforce's own data model: [salesforce/README.md](salesforce/README.md).
- Resource group `rg-intplat-backend-systems` (deleted by the kill switch, rebuilt by the pipeline).
